#!/usr/bin/python

#import psycopg2
import getopt
import os
import sys
import re

def configure_low_lat(file):
   print "\nConfiguration for Low-Latency\n"
   file.write('exchange = %s\n' % raw_input('Enter the AMQP Exchange name for Low-Latency: '))
   file.write('broker_ip = %s\n' % raw_input('Enter the Broker\'s IP for Low-Latency: '))
   file.write('broker_port = %s\n' % raw_input('Enter the port of the Broker for Low-Latency: '))
   file.write('amqp_queue = %s\n' % raw_input('Enter the AMQP queue for Low-Latency: '))
   file.write('ll_daemon_port = %s\n' % raw_input('Enter the port for Low-Latency daemon will listen on: '))
   file.write('ll_connections = %s\n' % raw_input('Enter the number of outstanding connections the Low-Latency daemon should allow: '))
   file.write('ll_lease_time = %s\n' % raw_input('Enter the lease time for the Low-Latency daemon: '))
   file.write('ll_check_interval = %s\n' % raw_input('Enter the Low-Latency check interval: '))

def configure_limits(file):
   print "\nConfiguration for Concurrency Limits\n"
   file.write('limits = %s\n' % raw_input('Enter the limits separated by commas (ie x_limit=10,y_limit-2): '))

def configure_dedicated_resource(file):
   print "\nConfiguration for Dedicated Resource\n"
   file.write('dedicatedscheduler = %s\n' % raw_input('Enter FQDN of the Dedicated Scheduler: '))

def configure_ec2e(file):
   print "\nConfiguration for EC2-Enhanced\n"
   answer = raw_input('Enable EC2 routing to the Small AMI [y/n] ? ')
   if answer.lower() == 'y':
      file.write('ec2e_route_small = True\n')
      file.write('ec2es_pub_key = %s\n' % raw_input('Enter filename containing the AWS Public Key for use with the Small Route: '))
      file.write('ec2es_priv_key = %s\n' % raw_input('Enter filename containing the AWS Private Key for use with the Small Route: '))
      file.write('ec2es_access_key = %s\n' % raw_input('Enter filename containing the AWS Access Key for use with the Small Route: '))
      file.write('ec2es_secret_key = %s\n' % raw_input('Enter filename containing the AWS Secret Key for use with the Small Route: '))
      file.write('ec2es_rsapub_key = %s\n' % raw_input('Enter filename containing the RSA Public Key for use with the Small Route: '))
      file.write('ec2es_bucket = %s\n' % raw_input('Enter S3 Storage Bucket name for use with the Small Route: '))
      file.write('ec2es_queue = %s\n' % raw_input('Enter SQS Queue name for use with the Small Route: '))
      file.write('ec2es_amiid = %s\n' % raw_input('Enter AMI ID for use with the Small Route: '))
   else:
      file.write('ec2e_route_small =\n')

   answer = raw_input('Enable EC2 routing to the Large AMI [y/n] ? ')
   if answer.lower() == 'y':
      file.write('ec2e_route_large = True\n')
      file.write('ec2elarge_pub_key = %s\n' % raw_input('Enter filename containing the AWS Public Key for use with the Large Route: '))
      file.write('ec2elarge_priv_key = %s\n' % raw_input('Enter filename containing the AWS Private Key for use with the Large Route: '))
      file.write('ec2elarge_access_key = %s\n' % raw_input('Enter filename containing the AWS Access Key for use with the Large Route: '))
      file.write('ec2elarge_secret_key = %s\n' % raw_input('Enter filename containing the AWS Secret Key for use with the Large Route: '))
      file.write('ec2elarge_rsapub_key = %s\n' % raw_input('Enter filename containing the RSA Public Key for use with the Large Route: '))
      file.write('ec2elarge_bucket = %s\n' % raw_input('Enter S3 Storage Bucket name for use with the Large Route: '))
      file.write('ec2elarge_queue = %s\n' % raw_input('Enter SQS Queue name for use with the Large Route: '))
      file.write('ec2elarge_amiid = %s\n' % raw_input('Enter AMI ID for use with the Large Route: '))
   else:
      file.write('ec2e_route_large =\n')

   answer = raw_input('Enable EC2 routing to the X-Large AMI [y/n] ? ')
   if answer.lower() == 'y':
      file.write('ec2e_route_xlarge = True\n')
      file.write('ec2exlarge_pub_key = %s\n' % raw_input('Enter filename containing the AWS Public Key for use with the X-Large Route: '))
      file.write('ec2exlarge_priv_key = %s\n' % raw_input('Enter filename containing the AWS Private Key for use with the X-Large Route: '))
      file.write('ec2exlarge_access_key = %s\n' % raw_input('Enter filename containing the AWS Access Key for use with the X-Large Route: '))
      file.write('ec2exlarge_secret_key = %s\n' % raw_input('Enter filename containing the AWS Secret Key for use with the X-Large Route: '))
      file.write('ec2exlarge_rsapub_key = %s\n' % raw_input('Enter filename containing the RSA Public Key for use with the X-Large Route: '))
      file.write('ec2exlarge_bucket = %s\n' % raw_input('Enter S3 Storage Bucket name for use with the X-Large Route: '))
      file.write('ec2exlarge_queue = %s\n' % raw_input('Enter SQS Queue name for use with the X-Large Route: '))
      file.write('ec2exlarge_amiid = %s\n' % raw_input('Enter AMI ID for use with the X-Large Route: '))
   else:
      file.write('ec2e_route_xlarge =\n')

   answer = raw_input('Enable EC2 routing to the High-Compute Medium AMI [y/n] ? ')
   if answer.lower() == 'y':
      file.write('ec2e_route_hcmedium = True\n')
      file.write('ec2ehcm_pub_key = %s\n' % raw_input('Enter filename containing the AWS Public Key for use with the High-Compute Medium Route: '))
      file.write('ec2ehcm_priv_key = %s\n' % raw_input('Enter filename containing the AWS Private Key for use with the High-Compute Medium Route: '))
      file.write('ec2ehcm_access_key = %s\n' % raw_input('Enter filename containing the AWS Access Key for use with the High-Compute Medium Route: '))
      file.write('ec2ehcm_secret_key = %s\n' % raw_input('Enter filename containing the AWS Secret Key for use with the High-Compute Medium Route: '))
      file.write('ec2ehcm_rsapub_key = %s\n' % raw_input('Enter filename containing the RSA Public Key for use with the High-Compute Medium Route: '))
      file.write('ec2ehcm_bucket = %s\n' % raw_input('Enter S3 Storage Bucket name for use with the High-Compute Medium Route: '))
      file.write('ec2ehcm_queue = %s\n' % raw_input('Enter SQS Queue name for use with the High-Compute Medium Route: '))
      file.write('ec2ehcm_amiid = %s\n' % raw_input('Enter AMI ID for use with the High-Compute Medium Route: '))
   else:
      file.write('ec2e_route_hcmedium =\n')

   answer = raw_input('Enable EC2 routing to the High-Compute Large AMI [y/n] ? ')
   if answer.lower() == 'y':
      file.write('ec2e_route_hcelarge = True\n')
      file.write('ec2ehcel_pub_key = %s\n' % raw_input('Enter filename containing the AWS Public Key for use with the High-Compute Large Route: '))
      file.write('ec2ehcel_priv_key = %s\n' % raw_input('Enter filename containing the AWS Private Key for use with the High-Compute Large Route: '))
      file.write('ec2ehcel_access_key = %s\n' % raw_input('Enter filename containing the AWS Access Key for use with the High-Compute Large Route: '))
      file.write('ec2ehcel_secret_key = %s\n' % raw_input('Enter filename containing the AWS Secret Key for use with the High-Compute Large Route: '))
      file.write('ec2ehcel_rsapub_key = %s\n' % raw_input('Enter filename containing the RSA Public Key for use with the High-Compute Large Route: '))
      file.write('ec2ehcel_bucket = %s\n' % raw_input('Enter S3 Storage Bucket name for use with the High-Compute Large Route: '))
      file.write('ec2ehcel_queue = %s\n' % raw_input('Enter SQS Queue name for use with the High-Compute Large Route: '))
      file.write('ec2ehcel_amiid = %s\n' % raw_input('Enter AMI ID for use with the High-Compute Large Route: '))
   else:
      file.write('ec2e_route_hcelarge =\n')

def configure_ha_scheduler(file):
   print "\nConfiguration for HA Scheduler\n"
   file.write('sharedfs = %s\n' % raw_input('Enter the mount point for the shared filesystem: '))

def configure_quill(file):
   print "\nConfiguration for Quill\n"
   file.write('db_node_name = %s\n' % raw_input('Enter the Database Server FQDN: '))
   file.write('qrpw = %s\n' % raw_input('Enter the quillreader password: '))
   file.write('qwpw = %s\n' % raw_input('Enter the quillwriter password: '))

def main(argv=None):
   if argv is None:
      argv = sys.argv

   config_dir = '/etc/puppet/modules/condor/node_configs'
   features = { 'dedicated_resource': False,
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
                'viewserver': False
              }

   if os.path.exists(config_dir) == False:
      os.makedirs(config_dir)

   long_opts = ['node_name']
   long_opts.extend(features.keys())
   try:
      opts, args = getopt.getopt(argv[1:], 'n:', long_opts)
   except getopt.GetoptError, error:
      print str(error)
      return(1)

   node = ''
   for option, arg in opts:
      if option in ('-n', '--node_name'):
         node = arg
      else:
         match = re.match('--(.*)', option)
         if match != None and match.groups() != None:
            features[match.groups()[0]] = True

#   for key in features.keys():
#      print '%s = %s' % (key, features[key])

   if node == '':
      print 'No node name supplied.  Exiting.'
   else:
      config = open('%s/%s' % (config_dir, node), 'w')
      for feature in features.keys():
         if features[feature] == True:
            config.write('%s\n' % feature)
            if feature == 'low_latency':
               configure_low_lat(config)
            elif feature == 'limits':
               configure_limits(config)
            elif feature == 'dedicated_resource':
               configure_dedicated_resource(config)
            elif feature == 'ec2e':
               if features['ec2'] == False:
                  config.write('ec2\n')
               configure_ec2e(config)
            elif feature == 'ha_scheduler':
               configure_ha_scheduler(config)
            elif feature == 'quill':
               configure_quill(config)
            elif feature == 'dbmsd':
               if features['quill'] == False:
                  config.write('quill\n');
                  configure_quill(config)
            elif feature == 'dedicated_preemption':
               if features['dedicated_scheduler'] == False:
                  print "Unable to enable Dedicated Preemption on %s because it is not a Dedicated Scheduler" % node


if __name__ == '__main__':
    sys.exit(main())

