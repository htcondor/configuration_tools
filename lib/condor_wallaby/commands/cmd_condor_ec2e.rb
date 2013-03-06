# cmd_condor_ec2e.rb: Commands for configuring condor's EC2 Enhanced
#
# Copyright (c) 2013 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'tempfile'
require 'condor_wallaby/configparser'
require 'condor_wallaby/commandoptions'
require 'condor_wallaby/commandargs'

module Wallaroo
  module Shell
    module Ec2eArgs
      def def_include
        "EC2Enhanced"
      end

      def noun
        "route"
      end

      def env_prefix
        "CONDOR_EC2E_ROUTE"
      end

#      def name
#        config[:name] || ENV["CONDOR_EC2E_ROUTE_NAME"] || nil
#      end
#
#      def requirements
#        n = :requirements
#        config[n] || fdata(n) || get_env("CONDOR_EC2E_ROUTE_REQUIREMENTS") || base[n] || nil
#      end
#
#      def instance_type
#        n = :instance_type
#        config[n] || fdata(n) || get_env("CONDOR_EC2E_ROUTE_INSTANCE_TYPE") || base[n] || nil
#      end
#
#      def amazon_public_key
#        n = :amazonpublickey
#        config[n] || fdata(n) || get_env('CONDOR_EC2E_ROUTE_AWS_PUBLIC_KEY') || base[n] || nil
#      end
#
#      def amazonprivatekey
#        n = :amazonprivatekey
#        config[n] || fdata(n) || get_env('CONDOR_EC2E_ROUTE_AWS_PRIVATE_KEY') || base[n] || nil
#      end
#
#      def amazonaccesskey
#        n = :amazonaccesskey
#        config[n] || fdata(n) || get_env('CONDOR_EC2E_ROUTE_AWS_ACCESS_KEY') || base[n] || nil
#      end
#
#      def amazonsecretkey
#        n = :amazonsecretkey
#        config[n] || fdata(n) || get_env('CONDOR_EC2E_ROUTE_AWS_SECRET_KEY') || base[n] || nil
#      end
#
#      def rsapublickey
#        n = :rsapublickey
#        config[n] || fdata(n) || get_env('CONDOR_EC2E_ROUTE_RSA_PUBLIC_KEY') || base[n] || nil
#      end
#
#      def s3bucket
#        n = :s3bucket
#        config[n] || fdata(n) || get_env('CONDOR_EC2E_ROUTE_S3_BUCKET') || base[n] || nil
#      end
#
#      def sqsqueue
#        n = :sqsqueue
#        config[n] || fdata(n) || get_env('CONDOR_EC2E_ROUTE_SQS_QUEUE') || base[n] || nil
#      end
#
#      def ami
#        n = :ami
#        config[n] || fdata(n) || get_env('CONDOR_EC2E_ROUTE_AMI') || base[n] || nil
#      end
#
      def self.included(receiver)
        receiver.extend CmdArgs
      end

      module CmdArgs
        def cmd_args
          ["requirements", "instance-type", "amazon-public-key", "amazon-private-key", "amazon-access-key", "amazon-secret-key", "rsa-public-key", "s3-bucket", "sqs-queue", "ami"]
        end
      end

#      def config
#        @config ||= {}
#      end
#
#      def base
#        @basefeature ||= {}
#      end
    end

    module Ec2eRouteOpts
#      def init
#        @fdata = Hash.new {|h,k| h[k] = {}}
#        @options = {}
#      end

      def prefix
        "ec2e_routes_"
      end

#      def get_env(n)
#        return ENV[n].to_sym if ENV.keys.include?(n)
#        nil
#      end
#
#      def fdata(arg)
#        @fdata.keys.include?(name) ? @fdata[name][arg] : nil
#      end
#
#      def read_file
#        if @options.has_key?(:infile)
#          exit!(1, "#{@options[:infile]} no such file") if not File.exist?(@options[:infile])
#          @fdata.merge!(ConfigParser.parse(File.read(@options[:infile])))
#        end
#      end

      def form_route
        route = " [ GridResource = \"condor localhost $(COLLECTOR_HOST)\";"
        route += " Name = \"#{name}\";"
        route += " requirements = #{requirements};"
        route += " set_amazonpublickey = \"#{amazonpublickey}\";"
        route += " set_amazonprivatekey = \"#{amazonprivatekey}\";"
        route += " set_amazonaccesskey = \"#{amazonaccesskey}\";"
        route += " set_amazonsecretkey = \"#{amazonsecretkey}\";"
        route += " set_rsapublickey = \"#{rsapublickey}\";"
        route += " set_amazoninstancetype = \"#{instancetype}\";"
        route += " set_amazons3bucketname = \"#{s3bucket}\";"
        route += " set_amazonsqsqueuename = \"#{sqsqueue}\";"
        route += " set_amazonamiid = \"#{ami}\";"
        route += " set_remote_jobuniverse = 5; ]"
        route
      end

#      def self.included(receiver)
#        if receiver.respond_to?(:register_callback)
#          receiver.register_callback :after_option_parsing, :parse_args
#        end
#      end
#
#      def parse_args(*args)
#        if @options.has_key?(:base)
#          route = store.getFeature(prefix+@options[:base]).parameters["JOB_ROUTER_ENTRIES"]
#          route.split(';').each do |line|
#            nvp = line.split('=', 2)
#            cmd_args.each do |c|
#              if nvp[0].include?(c)
#                base[c.to_sym] = nvp[1].strip.tr('"', '')
#              end
#            end
#          end
#        end
#
#        exit!(1, "you must specify a name for the route") if args.size < 1 && (not name) && (not @options.has_key?(:infile))
#        config[:name] = args.shift if args.count > 0 && (not name) && (not @options.has_key?(:infile))
#        args.each do |arg|
#          nvp = arg.split('=', 2)
#          exit!(1, "#{nvp[0]} is not a valid option") if not cmd_args.include?(nvp[0].downcase)
#          config[nvp[0].downcase.to_sym] = nvp[1].downcase
#        end
#        read_file
#      end
    end
#
#    module Ec2eOptions
#      def init_option_parser
#        OptionParser.new do |opts|
#          opts.banner = "Usage:  wallaby #{self.class.opname} [OPTIONS] NAME ARG=VALUE ...\n#{self.class.description}"
#  
#          opts.on("-h", "--help", "displays this message") do
#            puts @oparser
#            exit
#          end
#
#          opts.on("-f", "--file INFILE", "read feature data from INFILE.") do |f|
#            @options[:infile] = f
#          end
#
#          opts.on("-i", "--include INCLUDE", "name of the feature to include (default EC2Enhanced)") do |inc|
#            config[:include] = inc
#          end
#
#          opts.on("-s", "--save", "save configuration to a file.  The file will be named after the #{noun} name") do
#            @options[:save] = true
#          end
#
#          extra_options(opts)
#        end
#      end
#
#      def extra_options(o)
#        nil
#      end
#    end

    class AddEc2eRoute < Command
      include Ec2eArgs
      include CommandArgs
      include Ec2eRouteOpts
      include CommandOptions

      def self.opname
        "add-ec2e-route"
      end
    
      def self.description
        "Add a route to be used with condor's EC2 Enhanced to the store."
      end
    
      def extra_options(o)
        o.on("-b", "--baseroute NAME", "base changes off route NAME") do |r|
          @options[:base] = r
        end
      end

      def act
        keys = @fdata.keys.empty? ? name : @fdata.keys
        keys.each do |k|
          config[:name] = k
          arg_list.each do |a|
            exit!(1, "you must specify #{a} for route #{name}") if self.send(a.to_sym) == nil
          end
          tf = Tempfile.new("ec2e_config")
          tf.write("#name #{prefix}#{name}\n")
          tf.write("#includes #{include}\n")
          tf.write("JOB_ROUTER_ENTRIES = $(JOB_ROUTER_ENTRIES)#{form_route}")
          tf.close
          Mrg::Grid::Config::Shell::FeatureImport.new(store, "").main([tf.path])
          FileUtils.cp(tf.path, "#{name}.route") if @options.has_key?(:save)
          tf.unlink
        end
        return 0
      end
    end

    class AddGroupEc2eRoute < Command
      include Ec2eRouteOpts

      def self.opname
        "add-ec2e-routes-to-group"
      end
    
      def self.description
        "Add EC2 Enhanced routes to a group."
      end
    
      register_callback :after_option_parsing, :parse_args
      def parse_args(*args)
        exit!(1, "incorrect number of arguments") if args.size < 2

        @group = args.shift
        @routes = args.collect {|n| prefix + n}
      end

      def act
        exit!(1, "group #{@group} does not exist") if store.checkGroupValidity([@group]) != []
        bad = store.checkFeatureValidity(@routes).collect {|n| n.gsub(/#{prefix}/, '')}
        exit!(1, "route(s) #{bad.join(', ')} do not exist") if bad != []
        g = store.getGroupByName(@group)
        g.modifyFeatures("ADD", @routes, {})
        return 0
      end
    end

    class AddNodeEc2eRoute < Command
      include Ec2eRouteOpts

      def self.opname
        "add-ec2e-routes-to-node"
      end
    
      def self.description
        "Add EC2 Enhanced routes to a node."
      end
    
      register_callback :after_option_parsing, :parse_args
      def parse_args(*args)
        exit!(1, "incorrect number of arguments") if args.size < 2

        @node = args.shift
        @routes = args.collect {|n| prefix + n}
      end

      def act
        exit!(1, "node #{@node} does not exist") if store.checkNodeValidity([@node]) != []
        bad = store.checkFeatureValidity(@routes).collect {|n| n.gsub(/#{prefix}/, '')}
        exit!(1, "route(s) #{bad.join(', ')} do not exist") if bad != []
        n = store.getNode(@node)
        n.identity_group.modifyFeatures("ADD", @routes, {})
        return 0
      end
    end

    class ReplaceGroupEc2eRoute < Command
      include Ec2eRouteOpts

      def self.opname
        "replace-ec2e-routes-on-group"
      end
    
      def self.description
        "Replace EC2 Enhanced routes on a group."
      end
    
      register_callback :after_option_parsing, :parse_args
      def parse_args(*args)
        exit!(1, "incorrect number of arguments") if args.size < 2

        @group = args.shift
        @routes = args.collect {|n| prefix + n}
      end

      def act
        exit!(1, "group #{@group} does not exist") if store.checkGroupValidity([@group]) != []
        bad = store.checkFeatureValidity(@routes).collect {|n| n.gsub(/#{prefix}/, '')}
        exit!(1, "route(s) #{bad.join(', ')} do not exist") if bad != []
        g = store.getGroupByName(@group)
        g.modifyFeatures("REPLACE", @routes, {})
        return 0
      end
    end

    class ReplaceNodeEc2eRoute < Command
      include Ec2eRouteOpts

      def self.opname
        "replace-ec2e-routes-on-node"
      end
    
      def self.description
        "Replace EC2 Enhanced routes on a node."
      end
    
      register_callback :after_option_parsing, :parse_args
      def parse_args(*args)
        exit!(1, "incorrect number of arguments") if args.size < 2

        @node = args.shift
        @routes = args.collect {|n| prefix + n}
      end

      def act
        exit!(1, "node #{@node} does not exist") if store.checkNodeValidity([@node]) != []
        bad = store.checkFeatureValidity(@routes).collect {|n| n.gsub(/#{prefix}/, '')}
        exit!(1, "route(s) #{bad.join(', ')} do not exist") if bad != []
        n = store.getNode(@node)
        n.identity_group.modifyFeatures("REPLACE", @routes, {})
        return 0
      end
    end

    class ModifyEc2eRoute < Command
      include Ec2eArgs
      include CommandArgs
      include Ec2eRouteOpts
      include CommandOptions

      def self.opname
        "modify-ec2e-route"
      end
    
      def self.description
        "Modify an EC2 Enhanced route in the store."
      end
    
      def parse_args(*args)
        exit!(1, "incorrect number of args") if args.count < 2
        config[:name] = args.shift
        args.each do |arg|
          nvp = arg.split('=', 2)
          exit!(1, "#{nvp[0]} is not a valid option") if not arg_list.include?(nvp[0].downcase)
          config[nvp[0].downcase.to_sym] = nvp[1].downcase
        end
        read_file
      end

      def act
        bad = store.checkFeatureValidity([prefix+name]).collect {|n| n.gsub(/#{prefix}/, '')}
        exit!(1, "route #{bad.join(', ')} does not exist") if bad != []
        feature = store.getFeature(prefix+name)
        route = feature.parameters["JOB_ROUTER_ENTRIES"]

        arg_list.each do |a|
          if self.send(a) == nil
            route =~ /#{a.gsub(/_/, '')}[\w ]*=\s*"*([^;]+)"*/
            config[a.to_sym] = $1 if $1
          end
        end
        feature.modifyParams("ADD", {"JOB_ROUTER_ENTRIES"=>"$(JOB_ROUTER_ENTRIES)#{form_route}"}, {})
        return 0
      end
    end

    class RemoveEc2eRoute < Command
      include Ec2eRouteOpts

      def self.opname
        "remove-ec2e-route"
      end
    
      def self.description
        "Remove an EC2 Enhanced route from the store."
      end
    
      register_callback :after_option_parsing, :parse_args
      def parse_args(*args)
        exit!(1, "incorrect number of arguments") if args.size < 1

        @routes = args.collect {|n| prefix + n}
      end

      def act
        bad = store.checkFeatureValidity(@routes).collect {|n| n.gsub(/#{prefix}/, '')}
        exit!(1, "routes #{bad.join(', ')} do not exist") if bad != []
        store.removeFeature(@routes)
        return 0
      end
    end
  end
end
