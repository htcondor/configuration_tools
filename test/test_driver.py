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
from condorutils.osutil import run_cmd
from condorutils.readconfig import read_condor_config
from qmf.console import Session
from wallabyclient import WallabyHelpers
from wallabyclient.exceptions import WallabyStoreError

nodename = 'unit_test'
checkin_time = 60
config_file = './condor_config.configd'
log_file = './configd.log'
override_dir = './override'
override_file = './override.param'

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
   run_cmd('qpidd')
   sys.exit(0)

time.sleep(2)

# Start the store
print 'Starting the store'
store_pid = os.fork()
if store_pid == 0:
   env = {}
   if 'RUBYLIB' in os.environ.keys():
      env['RUBYLIB'] = os.environ['RUBYLIB']
   run_cmd('./store.rb', environ = env)
   print 'About to exit store child thread'
   sys.exit(0)

time.sleep(2)

# Start condor
print 'Starting condor'
condor_pid = os.fork()
if condor_pid == 0:
   env = {}
   env['CONDOR_CONFIG'] = '/etc/condor/condor_config'
   env['_CONDOR_DAEMON_LIST'] = 'MASTER'
   env['_CONDOR_LOG'] = '.'
   env['_CONDOR_LOCK'] = '.'
   (rcode, out, err) = run_cmd('condor_master', environ = env)
   sys.exit(0)

# Start the configd
print 'Starting configd'
configd_pid = os.fork()
if configd_pid == 0:
   env = {}
   if 'PYTHONPATH' in os.environ.keys():
      env['PYTHONPATH'] = os.environ['PYTHONPATH']
   env['CONDOR_CONFIG'] = '/etc/condor/condor_config'
   env['_CONDOR_LOCAL_CONFIG_DIR'] = '../config'
   env['_CONDOR_CONFIGD_CHECK_INTERVAL'] = str(checkin_time)
   env['_CONDOR_QMF_BROKER_HOST'] = '127.0.0.1'
   env['_CONDOR_QMF_BROKER_PORT'] = '5672'
   env['_CONDOR_CONFIGD_OVERRIDE_DIR'] = override_dir
   env['_CONDOR_LOG'] = '.'
   (rcode, out, err) = run_cmd('../condor_configd -d -l %s -m %s -h %s' % (log_file, config_file, nodename), environ = env)
   sys.exit(0)

# Setup the connection to the store
session = Session()
session.addBroker('amqp://127.0.0.1:5672')
store = []
try:
   (agent, store) = WallabyHelpers.get_store_objs(session)
except Exception, error:
   print 'Error: %s' % error.error_str

if store == []:
   os.killpg(os.getpgid(store_pid), 9)
   os.killpg(os.getpgid(configd_pid), 9)
   os.killpg(os.getpgid(broker_pid), 9)
   run_cmd('killall condor_master')
   sys.exit(1)

# Wait until the Node object is created in the store, which means the configd
# has started up and contacted the store
result = store.checkNodeValidity(nodename)
while result.status != 0:
   time.sleep(1)
   result = store.checkNodeValidity(nodename)

# Get the node object
result = store.getNode(nodename)
if result.status != 0:
   print 'Error: Failed to retrieve node object'
   os.killpg(os.getpgid(store_pid), 9)
   os.killpg(os.getpgid(configd_pid), 9)
   os.killpg(os.getpgid(broker_pid), 9)
   run_cmd('killall condor_master')
   sys.exit(1)
else:
   node = agent.getObjects(_objectId=result.outArgs['obj'])[0]

try:
   # Test 1 - Test the initial checkin
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

   # Test 2 - Verify a new config version is in the config file (should be 0
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

   # Test 3 - Verify configd checks in with the store periodically
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

   # Test 4 - Test config retrieval if new version found at wallaby
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

   # Test 5 - Test files in the override directory are included in the config
   print 'Testing override directory files override values in config: \t',
   try:
      new_value = read_condor_config('CONFIGD', ['TEST_PARAM'], environ={'CONDOR_CONFIG':config_file}, permit_param_only = False)['test_param']
   except:
      new_value = old_value
   if new_value != old_value:
      print 'PASS (%s != %s)' % (old_value, new_value)
   else:
      print 'FAILED (%s == %s)' % (old_value, new_value)

   # Add features and groups to the node
   grp_name = WallabyHelpers.get_id_group_name(node, session)
   node_grp = WallabyHelpers.get_group(session, store, grp_name)
   node.modifyMemberships('add', ['TestGroup'], {})
   node_grp.modifyFeatures('add', ['TestFeature'], {})
   node.update()
   node_grp.update()

   # Test 6 - Verify older config version causes config retrieval
   print 'Testing older version causes config retrieval: \t\t\t',
   node.setLastUpdatedVersion(version-1)
   time.sleep(checkin_time+5)
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

   # Test 7 - Test WallabyGroups is updated
   print 'Testing WallabyGroups was updated: \t\t\t\t',
   try:
      value = read_condor_config('', ['WallabyGroups'], environ={'CONDOR_CONFIG':config_file})['wallabygroups']
   except:
      value = ''
   if 'TestGroup' in value:
      print 'PASS'
   else:
      print 'FAILED (%s)' % value

   # Test 8 - Test WallabyFeatures is updated
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

   # Test 9 - Test event (1 target) causes config retrieval
   print 'Testing event (1 target) causes config retrieval: \t\t',
   old_version = version
   node.setLastUpdatedVersion(version+1)
   store.raiseEvent([nodename])
   time.sleep(8)
   try:
      version = int(read_condor_config('', ['WALLABY_CONFIG_VERSION'], environ={'CONDOR_CONFIG':config_file})['wallaby_config_version'])
   except:
      print 'Error: Failed to find WALLABY_CONFIG_VERSION in config file'
      version = old_version
   if old_version != version:
      print 'PASS (%d != %d)' % (version, old_version)
   else:
      print 'FAILED (%d == %d)' % (version, old_version)

   # Test 10 - Test WallabyGroups is updated
   print 'Testing WallabyGroups was updated: \t\t\t\t',
   try:
      value = read_condor_config('', ['WallabyGroups'], environ={'CONDOR_CONFIG':config_file})['wallabygroups']
   except:
      value = 'ERROR'
   if value == '""':
      print 'PASS'
   else:
      print 'FAILED (%s)' % value

   # Test 11 - Test WallabyFeatures is updated
   print 'Testing WallabyFeatures was updated: \t\t\t\t',
   try:
      value = read_condor_config('', ['WallabyFeatures'], environ={'CONDOR_CONFIG':config_file})['wallabyfeatures']
   except:
      value = 'ERROR'
   if value == '""':
      print 'PASS'
   else:
      print 'FAILED (%s)' % value

   # Test 12 - Test event (>1 target) causes config retrieval
   print 'Testing event (>1 targets) causes config retrieval: \t\t',
   old_version = version
   node.setLastUpdatedVersion(version+1)
   store.raiseEvent([nodename, 'node1', 'node2'])
   time.sleep(8)
   try:
      version = int(read_condor_config('', ['WALLABY_CONFIG_VERSION'], environ={'CONDOR_CONFIG':config_file})['wallaby_config_version'])
   except:
      print 'Error: Failed to find WALLABY_CONFIG_VERSION in config file'
      version = old_version
   if old_version != version:
      print 'PASS (%d != %d)' % (version, old_version)
   else:
      print 'FAILED (%d == %d)' % (version, old_version)

   # Test 13 - Test event not for this node does not cause a config retrieval
   print 'Testing not all events cause config retrieval: \t\t\t',
   old_version = version
   node.setLastUpdatedVersion(version+1)
   store.raiseEvent(['node1', 'node2'])
   time.sleep(8)
   try:
      version = int(read_condor_config('', ['WALLABY_CONFIG_VERSION'], environ={'CONDOR_CONFIG':config_file})['wallaby_config_version'])
   except:
      print 'Error: Failed to find WALLABY_CONFIG_VERSION in config file'
      version = old_version
   if old_version == version:
      print 'PASS (%d == %d)' % (version, old_version)
   else:
      print 'FAILED (%d != %d)' % (version, old_version)

   os.remove('%s/%s' % (override_dir, override_file))

except Exception, error:
   print 'Error: Exception raised: %s' % error
   os.killpg(os.getpgid(store_pid), 9)
   os.killpg(os.getpgid(configd_pid), 9)
   os.killpg(os.getpgid(broker_pid), 9)
   run_cmd('killall condor_master')

# Shut everything down
os.killpg(os.getpgid(configd_pid), 9)
os.killpg(os.getpgid(store_pid), 9)
os.killpg(os.getpgid(broker_pid), 9)
run_cmd('killall condor_master')
