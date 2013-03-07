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

      def self.included(receiver)
        receiver.extend CmdArgs
      end

      module CmdArgs
        def cmd_args
          ["requirements", "instance-type", "amazon-public-key", "amazon-private-key", "amazon-access-key", "amazon-secret-key", "rsa-public-key", "s3-bucket", "sqs-queue", "ami"]
        end
      end
    end

    module Ec2eRouteOpts
      def prefix
        "ec2e_routes_"
      end

      def form_route
        route = " [ GridResource = \"condor localhost $(COLLECTOR_HOST)\";"
        route += " Name = \"#{name}\";"
        route += " requirements = #{requirements};"
        route += " set_amazonpublickey = \"#{amazon_public_key}\";"
        route += " set_amazonprivatekey = \"#{amazon_private_key}\";"
        route += " set_amazonaccesskey = \"#{amazon_access_key}\";"
        route += " set_amazonsecretkey = \"#{amazon_secret_key}\";"
        route += " set_rsapublickey = \"#{rsa_public_key}\";"
        route += " set_amazoninstancetype = \"#{instance_type}\";"
        route += " set_amazons3bucketname = \"#{s3_bucket}\";"
        route += " set_amazonsqsqueuename = \"#{sqs_queue}\";"
        route += " set_amazonamiid = \"#{ami}\";"
        route += " set_remote_jobuniverse = 5; ]"
        route
      end

      def write_file
        f = Tempfile.new("ec2e_config")
        f.write("#name #{prefix}#{name}\n")
        f.write("#includes #{include}\n")
        f.write("JOB_ROUTER_ENTRIES = $(JOB_ROUTER_ENTRIES)#{form_route}")
        f.close
        FileUtils.cp(f.path, "#{name}.route") if @options.has_key?(:save)
        f
      end
    end

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
            exit!(1, "you must specify #{a} for route #{name}") if self.send(a.gsub(/-/,'_').to_sym) == nil
          end
          tf = write_file
          Mrg::Grid::Config::Shell::FeatureImport.new(store, "").main([tf.path])
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
          config[nvp[0].gsub(/-/, '_').downcase.to_sym] = nvp[1].downcase
        end
        read_file
      end

      def act
        bad = store.checkFeatureValidity([prefix+name]).collect {|n| n.gsub(/#{prefix}/, '')}
        exit!(1, "route #{bad.to_s} does not exist") if bad != []
        feature = store.getFeature(prefix+name)
        route = feature.parameters["JOB_ROUTER_ENTRIES"]

        arg_list.each do |a|
          if self.send(a.gsub(/-/, '_')) == nil
            route =~ /#{a.gsub(/-/, '')}[\w ]*=\s*([^;]+)/
            val = $1
            config[a.gsub(/-/, '_').to_sym] = val.tr('"', '') if val
          end
        end
        write_file.unlink
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
