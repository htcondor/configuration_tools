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
from condorutils.osutil import run_cmd
from condorutils.readconfig import read_condor_config
from qmf.console import Session
from wallabyclient import WallabyHelpers

nodename = 'unit_test'
checkin_time = 30
config_file = './condor_config.configd'
log_file = './configd.log'

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

# Start the configd
print 'Starting configd'
configd_pid = os.fork()
if configd_pid == 0:
   env = {}
   if 'PYTHONPATH' in os.environ.keys():
      env['PYTHONPATH'] = os.environ['PYTHONPATH']
   env['CONDOR_CONFIG'] = '../config/99configd.config'
   env['_CONDOR_QMF_CONFIGD_CHECK_INTERVAL'] = str(checkin_time)
   env['_CONDOR_QMF_BROKER_HOST'] = '127.0.0.1'
   env['_CONDOR_QMF_BROKER_PORT'] = '5672'
   (rcode, out, err) = run_cmd('../condor_configd -l %s -m %s -h %s' % (log_file, config_file, nodename), environ = env)
   sys.exit(0)

# Setup the connection to the store
session = Session()
session.addBroker('amqp://127.0.0.1:5672')
store = []
try:
   store = session.getObjects(_class='Store', _package='com.redhat.grid.config')
except Exception, error:
   print 'Error: %s' % error

if store == []:
   print 'Unable to contact Configuration Store'
else:
   store = store[0]

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
  sys.exit(1)
else:
   node = session.getObjects(_objectId=result.outArgs['obj'])[0]

try:
   # Test 1 - Test the initial checkin
   print 'Testing initial checkin: \t\t\t\t\t',

   # The configd waits between 0-10 seconds before initial checking, so wait 12
   # seconds to verify configd has checked in with the store for the first time
   time.sleep(12)

   node.update()
   if node.last_checkin > 0:
      print 'PASS'
   else:
      print 'FAILED'

   # Test 2 - Verify a new config version is in the config file (should be 0
   # since this would be the first checkin)
   print 'Verifying config file pulled from store: \t\t\t',
   try:
      version = int(read_condor_config('WALLABY_CONFIG', ['VERSION'], environ={'CONDOR_CONFIG':config_file})['version'])
   except:
      print 'Error: Failed to find WALLABY_CONFIG_VERSION in config file'
      version = -1
   if version == 0:
      print 'PASS'
   else:
      print 'FAILED (%d!=0)' % version

   # Test 3 - Verify configd checkins in with the store periodically
   print 'Testing periodic checkin: \t\t\t\t\t',
   old_checkin = node.last_checkin
   time.sleep(checkin_time+1)
   node.update()
   if old_checkin < node.last_checkin:
      print 'PASS (%d < %d)' % (old_checkin, node.last_checkin)
   else:
      print 'FAILED (%d !< %d)' % (old_checkin, node.last_checkin)

   # Test 4 - Test config retrieval if new version found at wallaby
   print 'Testing periodic checkin retrieves new config: \t\t\t',
   node.setLastUpdatedVersion(version+1)
   time.sleep(checkin_time+1)
   old_version = version
   try:
      version = int(read_condor_config('WALLABY_CONFIG', ['VERSION'], environ={'CONDOR_CONFIG':config_file})['version'])
   except:
      print 'Error: Failed to find WALLABY_CONFIG_VERSION in config file'
      version = old_version
   if old_version != version:
      print 'PASS (%d != %d)' % (version, old_version)
   else:
      print 'FAILED (%d == %d)' % (version, old_version)

   # Test 5 - Verify older config version causes config retrieval
   print 'Testing older version causes config retrieval: \t\t\t',
   node.setLastUpdatedVersion(version-1)
   time.sleep(checkin_time+1)
   old_version = version
   try:
      version = int(read_condor_config('WALLABY_CONFIG', ['VERSION'], environ={'CONDOR_CONFIG':config_file})['version'])
   except:
      print 'Error: Failed to find WALLABY_CONFIG_VERSION in config file'
      version = old_version
   if old_version != version:
      print 'PASS (%d != %d)' % (version, old_version)
   else:
      print 'FAILED (%d == %d)' % (version, old_version)

   # Test 6 - Test event (1 target) causes config retrieval
   print 'Testing event (1 target 1 subsys) causes config retrieval: \t',
   old_version = version
   node.setLastUpdatedVersion(version+1)
   store.raiseEvent([nodename], True, ['master'])
   time.sleep(1)
   try:
      version = int(read_condor_config('WALLABY_CONFIG', ['VERSION'], environ={'CONDOR_CONFIG':config_file})['version'])
   except:
      print 'Error: Failed to find WALLABY_CONFIG_VERSION in config file'
      version = old_version
   if old_version != version:
      print 'PASS (%d != %d)' % (version, old_version)
   else:
      print 'FAILED (%d == %d)' % (version, old_version)

   # Test 7 - Test event (>1 target) causes config retrieval
   print 'Testing event (>1 targets 1 subsys) causes config retrieval: \t',
   old_version = version
   node.setLastUpdatedVersion(version+1)
   store.raiseEvent([nodename, 'node1', 'node2'], True, ['master'])
   time.sleep(1)
   try:
      version = int(read_condor_config('WALLABY_CONFIG', ['VERSION'], environ={'CONDOR_CONFIG':config_file})['version'])
   except:
      print 'Error: Failed to find WALLABY_CONFIG_VERSION in config file'
      version = old_version
   if old_version != version:
      print 'PASS (%d != %d)' % (version, old_version)
   else:
      print 'FAILED (%d == %d)' % (version, old_version)

   # Test 8 - Test event (1 target & >1 subsys) causes config retrieval
   print 'Testing event (1 target >1 subsys) causes config retrieval: \t',
   old_version = version
   node.setLastUpdatedVersion(version+1)
   store.raiseEvent([nodename], True, ['master', 'startd', 'schedd'])
   time.sleep(1)
   try:
      version = int(read_condor_config('WALLABY_CONFIG', ['VERSION'], environ={'CONDOR_CONFIG':config_file})['version'])
   except:
      print 'Error: Failed to find WALLABY_CONFIG_VERSION in config file'
      version = old_version
   if old_version != version:
      print 'PASS (%d != %d)' % (version, old_version)
   else:
      print 'FAILED (%d == %d)' % (version, old_version)

   # Test 9 - Test event (>1 target & >1 subsys) causes config retrieval
   print 'Testing event (>1 target >1 subsys) causes config retrieval: \t',
   old_version = version
   node.setLastUpdatedVersion(version+1)
   store.raiseEvent([nodename, 'node1', 'node2'], True, ['master', 'schedd'])
   time.sleep(1)
   try:
      version = int(read_condor_config('WALLABY_CONFIG', ['VERSION'], environ={'CONDOR_CONFIG':config_file})['version'])
   except:
      print 'Error: Failed to find WALLABY_CONFIG_VERSION in config file'
      version = old_version
   if old_version != version:
      print 'PASS (%d != %d)' % (version, old_version)
   else:
      print 'FAILED (%d == %d)' % (version, old_version)

   # Test 10 - Test event not for this node does not cause a config retrieval
   print 'Testing not all events cause config retrieval: \t\t\t',
   old_version = version
   node.setLastUpdatedVersion(version+1)
   store.raiseEvent(['node1', 'node2'], True, ['master', 'schedd'])
   time.sleep(1)
   try:
      version = int(read_condor_config('WALLABY_CONFIG', ['VERSION'], environ={'CONDOR_CONFIG':config_file})['version'])
   except:
      print 'Error: Failed to find WALLABY_CONFIG_VERSION in config file'
      version = old_version
   if old_version == version:
      print 'PASS (%d == %d)' % (version, old_version)
   else:
      print 'FAILED (%d != %d)' % (version, old_version)

except Exception, error:
   print 'Error: Exception raised: %s' % error
   os.killpg(os.getpgid(store_pid), 15)

# Shut everything down
os.killpg(os.getpgid(store_pid), 15)
