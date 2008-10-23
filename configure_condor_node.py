#!/usr/bin/python

#import psycopg2
import getopt
import os
import sys
import re
import signal
import getpass
from subprocess import *

def exit_signal_handler(signum, frame):
   sys.exit(0)

def print_help(name, list, desc):
   print 'usage: %s [-h|--help] -n <FQDN> action feature[,feature,...]' % os.path.basename(name)
   print '  -n - Fully Qualified Domain Name for the condor node to configure'
   print '  -h - Print help'
   print '\naction:'
   print '  -a|--add    - Add the feature(s) to the condor node'
   print '  -d|--delete - Remove the feature(s) from the condor node'
   print '\navailable features:'
   keys = list.keys()
   keys.sort()
   for feature in keys:
      print '  %-21s- %s' % (feature, desc[feature])
   print

def remove_fields(field_list, conf):
   # Remove provided fields
   for field in field_list:
      for line in conf:
         match = re.match('^(%s\s*=.*)$' % field, line)
         if match != None and match.groups() != None:
            conf.remove(match.groups()[0] + '\n')
            break

def configure_low_lat(conf, action):
   fields = [ 'exchange', 'broker_ip', 'broker_port', 'amqp_queue',
              'll_daemon_port', 'll_connections', 'll_lease_time',
              'll_check_interval' ]

   # Remove previous configuration it if exists
   remove_fields(fields, conf)

   if action == 'add':
      print "\nConfiguration for Low-Latency\n"
      conf.append('exchange = %s\n' % raw_input('Enter the AMQP Exchange name for Low-Latency: '))
      conf.append('broker_ip = %s\n' % raw_input('Enter the Broker\'s IP for Low-Latency: '))
      conf.append('broker_port = %s\n' % raw_input('Enter the port of the Broker for Low-Latency: '))
      conf.append('amqp_queue = %s\n' % raw_input('Enter the AMQP queue for Low-Latency: '))
      conf.append('ll_daemon_port = %s\n' % raw_input('Enter the port for Low-Latency daemon will listen on: '))
      conf.append('ll_connections = %s\n' % raw_input('Enter the number of outstanding connections the Low-Latency daemon should allow: '))
      conf.append('ll_lease_time = %s\n' % raw_input('Enter the lease time for the Low-Latency daemon: '))
      conf.append('ll_check_interval = %s\n' % raw_input('Enter the Low-Latency check interval: '))

def configure_limits(conf, action):
   fields = ['limits']

   # Remove previous configuration it if exists
   remove_fields(fields, conf)

   if action == 'add':
      print "\nConfiguration for Concurrency Limits\n"
      conf.append('limits = %s\n' % raw_input('Enter the limits separated by commas (ie x_limit=10,y_limit=2): '))

def configure_dedicated_resource(conf, action):
   fields = ['dedicatedscheduler']

   # Remove previous configuration it if exists
   remove_fields(fields, conf)
   if action == 'add':
      print "\nConfiguration for Dedicated Resource\n"
      conf.append('dedicatedscheduler = %s\n' % raw_input('Enter FQDN of the Dedicated Scheduler: '))

def configure_ec2e(conf, action):
   fields = [ 'ec2e_route_small',
              'ec2es_pub_key', 'ec2es_priv_key', 'ec2es_access_key',
              'ec2es_secret_key', 'ec2es_rsapub_key', 'ec2es_bucket',
              'ec2es_queue', 'ec2es_amiid',
              'ec2e_route_large',
              'ec2elarge_pub_key', 'ec2elarge_priv_key',
              'ec2elarge_access_key', 'ec2elarge_secret_key',
              'ec2elarge_rsapub_key', 'ec2elarge_bucket', 'ec2elarge_queue',
              'ec2elarge_amiid',
              'ec2e_route_xlarge',
              'ec2exlarge_pub_key', 'ec2exlarge_priv_key',
              'ec2exlarge_access_key', 'ec2exlarge_secret_key',
              'ec2exlarge_rsapub_key', 'ec2exlarge_bucket', 'ec2exlarge_queue',
              'ec2exlarge_amiid',
              'ec2e_route_hcmedium',
              'ec2ehcm_pub_key', 'ec2ehcm_priv_key', 'ec2ehcm_access_key',
              'ec2ehcm_secret_key', 'ec2ehcm_rsapub_key', 'ec2ehcm_bucket',
              'ec2ehcm_queue', 'ec2ehcm_amiid',
              'ec2e_route_hcelarge',
              'ec2ehcel_pub_key', 'ec2ehcel_priv_key', 'ec2ehcel_access_key',
              'ec2ehcel_secret_key', 'ec2ehcel_rsapub_key', 'ec2ehcel_bucket',
              'ec2ehcel_queue', 'ec2ehcel_amiid',
            ]

   # Remove previous configuration it if exists
   remove_fields(fields, conf)

   if action == 'add':
      print "\nConfiguration for EC2-Enhanced\n"
      answer = raw_input('Enable EC2 routing to the Small AMI type [y/n] ? ')
      if answer.lower() == 'y':
         conf.append('ec2e_route_small = True\n')
         conf.append('ec2es_pub_key = %s\n' % raw_input('Enter a filename containing an AWS Public Key for this route: '))
         conf.append('ec2es_priv_key = %s\n' % raw_input('Enter a filename containing an AWS Private Key for this route: '))
         conf.append('ec2es_access_key = %s\n' % raw_input('Enter a filename containing an AWS Access Key for this route: '))
         conf.append('ec2es_secret_key = %s\n' % raw_input('Enter a filename containing an AWS Secret Key for this route: '))
         conf.append('ec2es_rsapub_key = %s\n' % raw_input('Enter a filename containing an RSA Public Key for this route: '))
         conf.append('ec2es_bucket = %s\n' % raw_input('Enter an S3 Storage Bucket name for this route: '))
         conf.append('ec2es_queue = %s\n' % raw_input('Enter an SQS Queue name for this route: '))
         conf.append('ec2es_amiid = %s\n' % raw_input('Enter an AMI ID for use with this route: '))
      else:
         conf.append('ec2e_route_small =\n')

      answer = raw_input('Enable EC2 routing to the Large AMI type [y/n] ? ')
      if answer.lower() == 'y':
         conf.append('ec2e_route_large = True\n')
         conf.append('ec2elarge_pub_key = %s\n' % raw_input('Enter a filename containing an AWS Public Key for this route: '))
         conf.append('ec2elarge_priv_key = %s\n' % raw_input('Enter a filename containing an AWS Private Key for this route: '))
         conf.append('ec2elarge_access_key = %s\n' % raw_input('Enter a filename containing an AWS Access Key for this route: '))
         conf.append('ec2elarge_secret_key = %s\n' % raw_input('Enter a filename containing an AWS Secret Key for this route: '))
         conf.append('ec2elarge_rsapub_key = %s\n' % raw_input('Enter a filename containing an RSA Public Key for this route: '))
         conf.append('ec2elarge_bucket = %s\n' % raw_input('Enter an S3 Storage Bucket name for this route: '))
         conf.append('ec2elarge_queue = %s\n' % raw_input('Enter an SQS Queue name for this route: '))
         conf.append('ec2elarge_amiid = %s\n' % raw_input('Enter an AMI ID for this route: '))
      else:
         conf.append('ec2e_route_large =\n')

      answer = raw_input('Enable EC2 routing to the X-Large AMI type [y/n] ? ')
      if answer.lower() == 'y':
         conf.append('ec2e_route_xlarge = True\n')
         conf.append('ec2exlarge_pub_key = %s\n' % raw_input('Enter a filename containing an AWS Public Key for this route: '))
         conf.append('ec2exlarge_priv_key = %s\n' % raw_input('Enter a filename containing an AWS Private Key for this route: '))
         conf.append('ec2exlarge_access_key = %s\n' % raw_input('Enter a filename containing an AWS Access Key for this route: '))
         conf.append('ec2exlarge_secret_key = %s\n' % raw_input('Enter a filename containing an AWS Secret Key for this route: '))
         conf.append('ec2exlarge_rsapub_key = %s\n' % raw_input('Enter a filename containing an RSA Public Key for this route: '))
         conf.append('ec2exlarge_bucket = %s\n' % raw_input('Enter an S3 Storage Bucket name for this route: '))
         conf.append('ec2exlarge_queue = %s\n' % raw_input('Enter an SQS Queue name for this route: '))
         conf.append('ec2exlarge_amiid = %s\n' % raw_input('Enter an AMI ID for this route: '))
      else:
         conf.append('ec2e_route_xlarge =\n')

      answer = raw_input('Enable EC2 routing to the High-Compute Medium AMI type [y/n] ? ')
      if answer.lower() == 'y':
         conf.append('ec2e_route_hcmedium = True\n')
         conf.append('ec2ehcm_pub_key = %s\n' % raw_input('Enter a filename containing an AWS Public Key for this route: '))
         conf.append('ec2ehcm_priv_key = %s\n' % raw_input('Enter a filename containing an AWS Private Key for this route: '))
         conf.append('ec2ehcm_access_key = %s\n' % raw_input('Enter a filename containing an AWS Access Key for this route: '))
         conf.append('ec2ehcm_secret_key = %s\n' % raw_input('Enter a filename containing an AWS Secret Key for this route: '))
         conf.append('ec2ehcm_rsapub_key = %s\n' % raw_input('Enter a filename containing an RSA Public Key for this route: '))
         conf.append('ec2ehcm_bucket = %s\n' % raw_input('Enter an S3 Storage Bucket name for this route: '))
         conf.append('ec2ehcm_queue = %s\n' % raw_input('Enter an SQS Queue name for this route: '))
         conf.append('ec2ehcm_amiid = %s\n' % raw_input('Enter an AMI ID for this route: '))
      else:
         conf.append('ec2e_route_hcmedium =\n')

      answer = raw_input('Enable EC2 routing to the High-Compute Large AMI type [y/n] ? ')
      if answer.lower() == 'y':
         conf.append('ec2e_route_hcelarge = True\n')
         conf.append('ec2ehcel_pub_key = %s\n' % raw_input('Enter a filename containing an AWS Public Key for this route: '))
         conf.append('ec2ehcel_priv_key = %s\n' % raw_input('Enter a filename containing an AWS Private Key for this route: '))
         conf.append('ec2ehcel_access_key = %s\n' % raw_input('Enter a filename containing an AWS Access Key for this route: '))
         conf.append('ec2ehcel_secret_key = %s\n' % raw_input('Enter a filename containing an AWS Secret Key for this route: '))
         conf.append('ec2ehcel_rsapub_key = %s\n' % raw_input('Enter a filename containing an RSA Public Key for this route: '))
         conf.append('ec2ehcel_bucket = %s\n' % raw_input('Enter an S3 Storage Bucket name for this route: '))
         conf.append('ec2ehcel_queue = %s\n' % raw_input('Enter an SQS Queue name for this route: '))
         conf.append('ec2ehcel_amiid = %s\n' % raw_input('Enter an AMI ID for this route: '))
      else:
         conf.append('ec2e_route_hcelarge =\n')

def configure_ha_scheduler(conf, action):
   fields = ['sharedfs']

   # Remove previous configuration it if exists
   remove_fields(fields, conf)

   if action == 'add':
      print "\nConfiguration for HA Scheduler\n"
      conf.append('sharedfs = %s\n' % raw_input('Enter the mount point for the shared filesystem: '))

def configure_quill(conf, action):
   fields = ['db_node_name']

   # Remove previous configuration it if exists
   remove_fields(fields, conf)

   if action == 'add':
      print "\nConfiguration for Quill\n"
      conf.append('db_node_name = %s\n' % raw_input('Enter the Database Server FQDN: '))
   configure_db_users(conf, action)

def configure_db_users(conf, action):
   fields = ['qrpw', 'qwpw']

   # Remove previous configuration it if exists
   remove_fields(fields, conf)

   if action == 'add':
      for line in conf:
         if re.match('^qrpw\s*', line) != None:
            # Password information has already been configured, so don't
            # ask for it again
            return

      print "\nConfiguration for Database Access\n"
      pass1 = getpass.getpass('Enter the quillreader password: ')
      pass2 = getpass.getpass('Re-Enter the password for verification: ')
      while pass1 != pass2:
         print "Passwords do not match.  Try again."
         pass1 = getpass.getpass('Enter the quillreader password: ')
         pass2 = getpass.getpass('Re-Enter the password for verification: ')
      conf.append('qrpw = %s\n' % pass1)

      pass1 = getpass.getpass('Enter the quillwriter password: ')
      pass2 = getpass.getpass('Re-Enter the password for verification: ')
      while pass1 != pass2:
         print "Passwords do not match.  Try again."
         pass1 = getpass.getpass('Enter the quillwriter password: ')
         pass2 = getpass.getpass('Re-Enter the password for verification: ')
      conf.append('qwpw = %s\n' % pass1)

def process_feature_deps(feat, deps):
   feature_list = ''
   try:
      for dep in deps[feat].split(','):
         # Handle recursive deps
         feature_list += ',' + dep
         if dep in deps.keys():
            feature_list += process_feature_deps(dep, deps)
   except:
      pass

   return feature_list

def process_remove_deps(feat, deps):
   list = ''
   for key in deps.keys():
      for dep in deps[key].split(','):
         if feat == dep:
            list += ',' + key
            if key in deps.values():
               list += process_remove_deps(key, deps)
   return list

def main(argv=None):
   if argv is None:
      argv = sys.argv

   node_was_hacm = False
   config_dir = '/etc/puppet/modules/condor/node_configs'
   desc = { 'dedicated_resource': 'Make the condor node a Dedicated Resource',
            'dedicated_scheduler': 'Make the condor node a Dedicated Scheduler',
            'ha_scheduler': 'Make the condor node a Highly Available Scheduler',
            'ha_central_manager': 'Make the condor node a Highly Available Central Manager',
            'ec2': 'Enable the EC2 feature',
            'ec2e': 'Enable the EC2 Enhanced feature',
            'low_latency': 'Enable the Low-Latency feature',
            'concurrency_limits': 'Enable the Concurrency Limits feature',
            'quill': 'Enable quill',
            'dbmsd': 'Enable dbmsd',
            'dynamic_provisioning': 'Enable the Dynamic Provisioing feature',
            'dedicated_preemption': 'Enable Dedicated Preemption',
            'viewserver': 'Make the condor node a CondorView Server',
            'job_router': 'Enable the Job Router',
            'scheduler': 'Enable the Condor Scheduler daemon',
            'negotiator': 'Enable the Condor Negotiator daemon',
            'collector': 'Enable the Condor Collector daemon',
            'central_manager': 'Make the node a Central Manager (Negotiator and Collector)',
            'credd': 'Enable the Condor Credential daemon',
            'startd': 'Enable the Condor Start daemon (execution node)'
          }
   feature_deps = { 'ec2e': 'ec2,job_router',
                    'dedicated_preemption': 'dedicated_scheduler',
                    'dbmsd': 'quill',
                    'ha_scheduler': 'scheduler',
                    'dedicated_scheduler': 'scheduler',
                    'dedicated_resource': 'startd',
                    'ha_central_manager': 'central_manager',
                    'central_manager': 'negotiator,collector',
                    'viewserver': 'collector',
                    'low_latency': 'startd',
                    'job_router': 'scheduler'
                  }
   feature_list = { 'dedicated_resource': False,
                    'dedicated_scheduler': False,
                    'ha_scheduler': False,
                    'ha_central_manager': False,
                    'ec2': False,
                    'ec2e': False,
                    'low_latency': False,
                    'concurrency_limits': False,
                    'quill': False,
                    'dbmsd': False,
                    'dynamic_provisioning': False,
                    'dedicated_preemption': False,
                    'viewserver': False,
                    'job_router': False,
                    'scheduler': False,
                    'negotiator': False,
                    'collector': False,
                    'central_manager': False,
                    'credd': False,
                    'startd': False,
                  }

   # Set signal handlers
   signal.signal(signal.SIGINT, exit_signal_handler)
   signal.signal(signal.SIGTERM, exit_signal_handler)

   if os.path.exists(config_dir) == False:
      os.makedirs(config_dir)

   long_opts = ['add', 'delete', 'help', 'node_name']
   try:
      opts, args = getopt.getopt(argv[1:], 'a:d:hn:', long_opts)
   except getopt.GetoptError, error:
      print str(error)
      return(1)

   node = ''
   action = ''
   for option, arg in opts:
      if option in ('-h', '--help'):
         print_help(argv[0], feature_list, desc)
         return(0)
      if option in ('-n', '--node_name'):
         node = arg
      if option in ('-a', '--add'):
         if action == 'delete':
            print 'Only 1 action may be specified'
            return(1)
         action = 'add'
         features = arg
      if option in ('-d', '--delete'):
         if action == 'add':
            print 'Only 1 action may be specified'
            return(1)
         action = 'delete'
         features = arg
       
   if node == '':
      print 'No node name supplied.  Exiting'
      print_help(argv[0], feature_list, desc)
   elif action == '':
      print 'No action specified.  Exiting'
      print_help(argv[0], feature_list, desc)
   else:
      config = []
      if os.path.exists('%s/%s' % (config_dir, node)) == True:
         file = open('%s/%s' % (config_dir, node), 'r')
         for line in file.read().split('\n'):
            if line != '':
               config.append(line + '\n')
         file.close()
      if 'ha_central_manager\n' in config:
         node_was_hacm = True

      # Process any dependencies
      for feature in features.split(','):
         if action == 'add':
            dep_list = process_feature_deps(feature, feature_deps)
            if dep_list != '':
               features += dep_list
         elif action == 'delete':
            remove_list = process_remove_deps(feature, feature_deps)
            if remove_list != '':
               features += remove_list

      for feature in features.split(','):
         # Check if we have already configured this item (ie protect against
         # duplicate features provided)
         item_present = True
         if feature_list[feature] == False:
            feature_list[feature] = True
            try:
               config.index(feature + '\n')
            except:
               item_present = False

            # Add or remove the feature keyword along with any dependencies
            # if they exist
            if action == 'add' and item_present == False:
               config.append(feature + '\n')
            elif action == 'delete' and item_present == True:
               config.remove(feature + '\n')

            # Add or remove feature specific configs if needed
            if feature == 'low_latency':
               configure_low_lat(config, action)
            elif feature == 'limits':
               configure_limits(config, action)
            elif feature == 'dedicated_resource':
               configure_dedicated_resource(config, action)
            elif feature == 'ec2e':
               configure_ec2e(config, action)
            elif feature == 'ha_scheduler':
               configure_ha_scheduler(config, action)
            elif feature == 'quill':
               configure_quill(config, action)

      if raw_input('\nSave this configuration [y/n] ? ').lower() == 'y':
         file = open('%s/%s' % (config_dir, node), 'w')
         file.writelines(config)
         file.close()
         print 'Configuration saved'
         null = open('/dev/null', 'w')
         if ('ha_central_manager' in features) and \
            ((action == 'add' and node_was_hacm == False) or \
             (action == 'delete' and node_was_hacm == True)):
            # Need to tell other HA Central Managers to refresh their
            # configuration if this node is being added as a new HA CM
            # or if the node was an HA CM and is being removed from the
            # list
            os.chdir(config_dir)
            cmd = Popen('grep'+' -H' + ' ha_central_manager' + ' *', stdout=PIPE, shell=True)
            ha_cm_list = cmd.communicate()[0]
            for cm in ha_cm_list.split('\n'):
               match = re.match('^(.+):.+$', cm)
               if match != None and match.groups() != None:
                  refresh = Popen('/usr/bin/puppetrun' + ' --host' + ' %s' % match.groups()[0], shell=True, stdout=null, stderr=null)
                  status = os.waitpid(refresh.pid, 0)
            if action == 'delete':
               # Refesh the node being configured, since it won't be detected
               # as a node to refresh
               refresh = Popen('/usr/bin/puppetrun' + ' --host' + ' %s' % node, shell=True, stdout=null, stderr=null)
               status = os.waitpid(refresh.pid, 0)
         else:
            # Only tell the node configured to refresh its configuration
            refresh = Popen('/usr/bin/puppetrun' + ' --host' + ' %s' % node, shell=True, stdout=null, stderr=null)
            status = os.waitpid(refresh.pid, 0)
         null.close()
      else:
         print 'Configuration not saved'

if __name__ == '__main__':
    sys.exit(main())

