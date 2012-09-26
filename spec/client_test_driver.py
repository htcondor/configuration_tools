#!/usr/bin/python
#   Copyright 2008 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

import os
import sys
import time
import datetime
import shutil
import signal
import shlex
from condorutils.osutil import run_cmd
from condorutils.readconfig import read_condor_config
from qmf.console import Session
from wallabyclient import WallabyHelpers
from wallabyclient.exceptions import WallabyStoreError

nodename = 'unit_test'
checkin_time = 10
config_file = './condor_config.configd'
log_file = './configd.log'
override_dir = './override'
override_file = './override.param'
config_dir = '../config'

try:
   os.remove(config_file)
except:
   pass
try:
   os.remove(log_file)
except:
   pass

# Start the broker
print 'Starting the broker'
broker_pid = os.fork()
if broker_pid == 0:
   cmd = shlex.split('qpidd --log-to-stdout no --log-to-stderr no --log-to-syslog yes')
   os.execvp(cmd[0], cmd)
   print 'About to exit broker'
   sys.exit(0)

time.sleep(5)

# Start the store
print 'Starting the store'
store_pid = os.fork()
if store_pid == 0:
   env = {}
   if 'RUBYLIB' in os.environ.keys():
      env['RUBYLIB'] = os.environ['RUBYLIB']
   cmd = shlex.split('./store.rb')
   os.execve(cmd[0], cmd, env)
   print 'About to exit store child thread'
   sys.exit(0)

print 'Starting a second store'
bad_store_pid = os.fork()
if bad_store_pid == 0:
   env = {}
   if 'RUBYLIB' in os.environ.keys():
      env['RUBYLIB'] = os.environ['RUBYLIB']
   cmd = shlex.split('./store.rb')
   os.execve(cmd[0], cmd, env)
   print 'About to exit 2nd store child thread'
   sys.exit(0)

print 'Starting configd'
print 'Testing exit upon multiple configuration stores detected: \t',
configd_pid = os.fork()
if configd_pid == 0:
   env = {}
   if 'PYTHONPATH' in os.environ.keys():
      env['PYTHONPATH'] = os.environ['PYTHONPATH']
   env['CONDOR_CONFIG'] = '/etc/condor/condor_config'
   env['_CONDOR_LOCAL_CONFIG_DIR'] = config_dir
   env['_CONDOR_CONFIGD_CHECK_INTERVAL'] = str(checkin_time)
   env['_CONDOR_QMF_BROKER_HOST'] = '127.0.0.1'
   env['_CONDOR_QMF_BROKER_PORT'] = '5672'
   env['_CONDOR_CONFIGD_OVERRIDE_DIR'] = override_dir
   env['_CONDOR_LOG'] = '.'
   env['PATH'] = os.environ['PATH']
   cmd = shlex.split('../condor_configd -d -l %s -m %s -h %s' % (log_file, config_file, nodename))
   os.execve(cmd[0], cmd, env)
   print 'Exiting 1st configd pass'
   sys.exit(0)

# Give the config time to detect 2 configuration stores
time.sleep(20)

# Check if the configd process is still there
status = os.waitpid(configd_pid, os.WNOHANG)
if status != (0, 0):
   if os.WIFEXITED(status[1]) and os.WEXITSTATUS(status[1]) != 0 and status[0] == configd_pid:
      print 'PASS'
   else:
      print 'FAILED (Process exit not correct type "%d")' % os.WEXITSTATUS(status[1])
else:
   print 'FAILED (Configd still running)'

os.kill(bad_store_pid, 9)

# Connect to the broker
session = Session()
session.addBroker('amqp://127.0.0.1:5672')

# Wait until there is only 1 store running
while True:
   cnt = 0
   o = session.getAgents()
   for a in o:
      if a.label == 'com.redhat.grid.config:Store':
         cnt += 1
   if cnt == 1:
      break
   else:
      time.sleep(1)

# Start the configd
configd_pid = os.fork()
if configd_pid == 0:
   env = {}
   if 'PYTHONPATH' in os.environ.keys():
      env['PYTHONPATH'] = os.environ['PYTHONPATH']
   env['CONDOR_CONFIG'] = '/etc/condor/condor_config'
   env['_CONDOR_LOCAL_CONFIG_DIR'] = config_dir
   env['_CONDOR_CONFIGD_CHECK_INTERVAL'] = str(checkin_time)
   env['_CONDOR_QMF_BROKER_HOST'] = '127.0.0.1'
   env['_CONDOR_QMF_BROKER_PORT'] = '5672'
   env['_CONDOR_CONFIGD_OVERRIDE_DIR'] = override_dir
   env['_CONDOR_LOG'] = '.'
   env['PATH'] = os.environ['PATH']
   cmd = shlex.split('../condor_configd -d -l %s -m %s -h %s' % (log_file, config_file, nodename))
   os.execve(cmd[0], cmd, env)
   sys.exit(0)

# Setup the connection to the store
store = []
try:
   (agent, store) = WallabyHelpers.get_store_objs(session)
except Exception, error:
   print 'Error: %s' % error.error_str

if store == []:
   os.kill(store_pid, 9)
   os.kill(configd_pid, 9)
   os.kill(broker_pid, 9)
   sys.exit(1)

# Wait until the Node object is created in the store, which means the configd
# has started up and contacted the store
print "Waiting for the node object to be created in the store"
result = store.checkNodeValidity([nodename])
while result.invalidNodes != []:
   time.sleep(1)
   result = store.checkNodeValidity([nodename])

# Get the node object
result = store.getNode(nodename)
if result.status != 0:
   print 'Error: Failed to retrieve node object'
   os.kill(store_pid, 9)
   os.kill(configd_pid, 9)
   os.kill(broker_pid, 9)
   sys.exit(1)
else:
   node = agent.getObjects(_objectId=result.outArgs['obj'])[0]

try:
   # Test the initial checkin
   print 'Testing initial checkin: \t\t\t\t\t',

   # The configd waits between 0-10 seconds before initial checkin and can take
   # 5 seconds to find the store agent, so wait 17 seconds to verify configd
   # has checked in with the store for the first time
   time.sleep(17)

   node.update()
   if node.last_checkin > 0:
      print 'PASS'
   else:
      print 'FAILED'

   # Verify a new config version is in the config file (should be 0
   # since this would be the first checkin)
   print 'Verifying config file pulled from store: \t\t\t',
   try:
      version = int(read_condor_config('', ['WALLABY_CONFIG_VERSION'], environ={'CONDOR_CONFIG':config_file})['wallaby_config_version'])
   except:
      print 'Error: Failed to find WALLABY_CONFIG_VERSION in config file'
      version = -1
   if version == 1:
      print 'PASS'
   else:
      print 'FAILED (%d!=0)' % version

   # Verify configd checks in with the store periodically
   print 'Testing periodic checkin: \t\t\t\t\t',
   old_checkin = node.last_checkin
   time.sleep(checkin_time+5)
   node.update()
   if old_checkin < node.last_checkin:
      print 'PASS (%d < %d)' % (old_checkin, node.last_checkin)
   else:
      print 'FAILED (%d !< %d)' % (old_checkin, node.last_checkin)

   # Setup for testing override directory
   shutil.copy(override_file, override_dir)
   try:
      old_value = read_condor_config('CONFIGD', ['TEST_PARAM'], environ={'CONDOR_CONFIG':config_file}, permit_param_only = False)['test_param']
   except:
      old_value = 0

   # Test config retrieval if new version found at wallaby
   print 'Testing periodic checkin retrieves new config: \t\t\t',
   node.setLastUpdatedVersion(version+1)
   time.sleep(checkin_time+5)
   old_version = version
   try:
      version = int(read_condor_config('' , ['WALLABY_CONFIG_VERSION'], environ={'CONDOR_CONFIG':config_file})['wallaby_config_version'])
   except:
      print 'Error: Failed to find WALLABY_CONFIG_VERSION in config file'
      version = old_version
   if old_version != version:
      print 'PASS (%d != %d)' % (version, old_version)
   else:
      print 'FAILED (%d == %d)' % (version, old_version)

   # Test files in the override directory are included in the config
   print 'Testing override directory files override values in config: \t',
   try:
      new_value = read_condor_config('CONFIGD', ['TEST_PARAM'], environ={'CONDOR_CONFIG':config_file}, permit_param_only = False)['test_param']
   except:
      new_value = old_value
   if new_value != old_value:
      print 'PASS (%s != %s)' % (old_value, new_value)
   else:
      print 'FAILED (%s == %s)' % (old_value, new_value)

   # Restart the configd with no periodic checkin
   os.kill(configd_pid, 9)
   configd_pid = os.fork()
   if configd_pid == 0:
      env = {}
      if 'PYTHONPATH' in os.environ.keys():
         env['PYTHONPATH'] = os.environ['PYTHONPATH']
      env['CONDOR_CONFIG'] = '/etc/condor/condor_config'
      env['_CONDOR_LOCAL_CONFIG_DIR'] = config_dir
      env['_CONDOR_CONFIGD_CHECK_INTERVAL'] = '0'
      env['_CONDOR_QMF_BROKER_HOST'] = '127.0.0.1'
      env['_CONDOR_QMF_BROKER_PORT'] = '5672'
      env['_CONDOR_CONFIGD_OVERRIDE_DIR'] = override_dir
      env['_CONDOR_LOG'] = '.'
      env['PATH'] = os.environ['PATH']
      cmd = shlex.split('../condor_configd -d -l %s -m %s -h %s' % (log_file, config_file, nodename))
      os.execve(cmd[0], cmd, env)
      sys.exit(0)

   # The configd performs a checkin within 10 seconds on startup
   time.sleep(15)

   # Add features and groups to the node
   WallabyHelpers.add_group(session, store, 'TestGroup')
   grp_name = WallabyHelpers.get_id_group_name(node, session)
   node_grp = WallabyHelpers.get_group(session, store, grp_name)
   node.modifyMemberships('add', ['TestGroup'], {})
   node_grp.modifyFeatures('add', ['TestFeature'], {})
   node.update()
   node_grp.update()

   # Verify older config version causes config retrieval
   print 'Testing older version causes config retrieval: \t\t\t',
   node.setLastUpdatedVersion(version-1)
   store.raiseEvent([nodename])
   time.sleep(10)
   old_version = version
   try:
      version = int(read_condor_config('WALLABY', ['CONFIG_VERSION'], environ={'CONDOR_CONFIG':config_file}, permit_param_only = False)['config_version'])
   except:
      print 'Error: Failed to find WALLABY_CONFIG_VERSION in config file'
      version = old_version
   if old_version != version:
      print 'PASS (%d != %d)' % (version, old_version)
   else:
      print 'FAILED (%d == %d)' % (version, old_version)

   # Test WallabyGroups is updated
   print 'Testing WallabyGroups was updated: \t\t\t\t',
   try:
      value = read_condor_config('', ['WallabyGroups'], environ={'CONDOR_CONFIG':config_file})['wallabygroups']
   except:
      value = ''
   if 'TestGroup' in value:
      print 'PASS'
   else:
      print 'FAILED (%s)' % value

   # Test WallabyFeatures is updated
   print 'Testing WallabyFeatures was updated: \t\t\t\t',
   try:
      value = read_condor_config('', ['WallabyFeatures'], environ={'CONDOR_CONFIG':config_file})['wallabyfeatures']
   except:
      value = ''
   if 'TestFeature' in value:
      print 'PASS'
   else:
      print 'FAILED (%s)' % value

   # Remove the test features/groups
   node.modifyMemberships('remove', ['TestGroup'], {})
   node_grp.modifyFeatures('remove', ['TestFeature'], {})
   node.update()
   node_grp.update()

   # Test event (1 target) causes config retrieval
   print 'Testing event (1 target) causes config retrieval: \t\t',
   old_version = version
   node.setLastUpdatedVersion(version+1)
   store.raiseEvent([nodename])
   time.sleep(10)
   try:
      version = int(read_condor_config('', ['WALLABY_CONFIG_VERSION'], environ={'CONDOR_CONFIG':config_file})['wallaby_config_version'])
   except:
      print 'Error: Failed to find WALLABY_CONFIG_VERSION in config file'
      version = old_version
   if old_version != version:
      print 'PASS (%d != %d)' % (version, old_version)
   else:
      print 'FAILED (%d == %d)' % (version, old_version)

   # Test WallabyGroups is updated
   print 'Testing WallabyGroups was updated: \t\t\t\t',
   try:
      value = read_condor_config('', ['WallabyGroups'], environ={'CONDOR_CONFIG':config_file})['wallabygroups']
   except:
      value = 'ERROR'
   if value == '""':
      print 'PASS'
   else:
      print 'FAILED (%s)' % value

   # Test WallabyFeatures is updated
   print 'Testing WallabyFeatures was updated: \t\t\t\t',
   try:
      value = read_condor_config('', ['WallabyFeatures'], environ={'CONDOR_CONFIG':config_file})['wallabyfeatures']
   except:
      value = 'ERROR'
   if value == '""':
      print 'PASS'
   else:
      print 'FAILED (%s)' % value

   # Test event (>1 target) causes config retrieval
   print 'Testing event (>1 targets) causes config retrieval: \t\t',
   old_version = version
   node.setLastUpdatedVersion(version+1)
   store.raiseEvent([nodename, 'node1', 'node2'])
   time.sleep(10)
   try:
      version = int(read_condor_config('', ['WALLABY_CONFIG_VERSION'], environ={'CONDOR_CONFIG':config_file})['wallaby_config_version'])
   except:
      print 'Error: Failed to find WALLABY_CONFIG_VERSION in config file'
      version = -1
   if old_version != version:
      print 'PASS (%d != %d)' % (version, old_version)
   else:
      print 'FAILED (%d == %d)' % (version, old_version)

   # Test event not for this node does not cause a config retrieval
   print 'Testing not all events cause config retrieval: \t\t\t',
   old_version = version
   node.setLastUpdatedVersion(version+1)
   store.raiseEvent(['node1', 'node2'])
   time.sleep(10)
   try:
      version = int(read_condor_config('', ['WALLABY_CONFIG_VERSION'], environ={'CONDOR_CONFIG':config_file})['wallaby_config_version'])
   except:
      print 'Error: Failed to find WALLABY_CONFIG_VERSION in config file'
      version = -1
   if old_version == version:
      print 'PASS (%d == %d)' % (version, old_version)
   else:
      print 'FAILED (%d != %d)' % (version, old_version)

   os.remove('%s/%s' % (override_dir, override_file))

except Exception, error:
   print 'Error: Exception raised: %s' % error
   os.kill(store_pid, 9)
   os.kill(configd_pid, 9)
   os.kill(broker_pid, 9)

# Shut everything down
os.kill(configd_pid, 9)
os.kill(store_pid, 9)
os.kill(broker_pid, 9)
