# cmd_condor_ec2e.rb: Commands for configuring EC2 Enhanced
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

module Wallaroo
  module Shell
    module Ec2eArgs
      def include
        @config[:include] || fdata(:include) || "EC2Enhanced"
      end

      def name
        config[:name] || ENV["CONDOR_EC2E_ROUTE_NAME"] || nil
      end

      def requirements
        config[:requirements] || fdata(:requirements) || get_env("CONDOR_EC2E_ROUTE_REQUIREMENTS") || nil
      end

      def instance_type
        config[:instance_type] || fdata(:instance_type) || get_env("CONDOR_EC2E_ROUTE_INSTANCE_TYPE") || nil
      end

      def public_key
        config[:public_key] || fdata(:public_key) || get_env('CONDOR_EC2E_ROUTE_AWS_PUBLIC_KEY') || nil
      end

      def private_key
        config[:private_key] || fdata(:private_key) || get_env('CONDOR_EC2E_ROUTE_AWS_PRIVATE_KEY') || nil
      end

      def access_key
        config[:access_key] || fdata(:access_key) || get_env('CONDOR_EC2E_ROUTE_AWS_ACCESS_KEY') || nil
      end

      def secret_key
        config[:secret_key] || fdata(:secret_key) || get_env('CONDOR_EC2E_ROUTE_AWS_SECRET_KEY') || nil
      end

      def rsa_key
        config[:rsa_key] || fdata(:rsa_key) || get_env('CONDOR_EC2E_ROUTE_RSA_PUBLIC_KEY') || nil
      end

      def bucket
        config[:bucket] || fdata(:bucket) || get_env('CONDOR_EC2E_ROUTE_S3_BUCKET') || nil
      end

      def queue
        config[:queue] || fdata(:queue) || get_env('CONDOR_EC2E_ROUTE_SQS_QUEUE') || nil
      end

      def ami
        config[:ami] || fdata(:ami) || get_env('CONDOR_EC2E_ROUTE_AMI') || nil
      end

      def cmd_args
        ["name", "requirements", "instance_type", "public_key", "private_key", "access_key", "secret_key", "rsa_key", "bucket", "queue", "ami"]
      end

      def config
        @config ||= {}
      end
    end

    module Ec2eFeatureOpts
      def prefix
        "ec2e_routes_"
      end

      def get_env(n)
        return ENV[n].to_sym if ENV.keys.include?(n)
        nil
      end

      def fdata(arg)
        @fdata.keys.include?(name) ? @fdata[name][arg] : nil
      end

      def read_file
        @fdata = {}
        if @options.has_key?(:infile)
          exit!(1, "#{@options[:infile]} no such file") if not File.exist?(@options[:infile])
          @fdata = ConfigParser.parse(File.read(@options[:infile]))
        end
      end

      def form_route
        route = " [ GridResource = \"condor localhost $(COLLECTOR_HOST)\";"
        route += " Name = \"#{name}\";"
        route += " requirements = #{requirements};"
        route += " set_amazonpublickey = \"#{public_key}\";"
        route += " set_amazonprivatekey = \"#{private_key}\";"
        route += " set_amazonaccesskey = \"#{access_key}\";"
        route += " set_amazonsecretkey = \"#{secret_key}\";"
        route += " set_rsapublickey = \"#{rsa_key}\";"
        route += " set_amazoninstancetype = \"#{instance_type}\";"
        route += " set_amazons3bucketname = \"#{bucket}\";"
        route += " set_amazonsqsqueuename = \"#{queue}\";"
        route += " set_amazonamiid = \"#{ami}\";"
        route += " set_remote_jobuniverse = 5; ]"
        route
      end

      def self.included(receiver)
        if receiver.respond_to?(:register_callback)
          receiver.register_callback :after_option_parsing, :parse_args
        end
      end

      def parse_args(*args)
        args.each do |arg|
          nvp = arg.split('=', 2)
          exit!(1, "#{nvp[0]} is not a valid option") if not cmd_args.include?(nvp[0].downcase)
          config[nvp[0].downcase.to_sym] = nvp[1].downcase
        end
        read_file
      end
    end

    module Ec2eOptions
      def init_option_parser
        @options = {}
        OptionParser.new do |opts|
          opts.banner = "Usage:  wallaby #{self.class.opname} [OPTIONS] ARG=VALUE ...\n#{self.class.description}"
  
          opts.on("-h", "--help", "displays this message") do
            puts @oparser
            exit
          end

          opts.on("-f", "--file INFILE", "read feature data from INFILE.") do |f|
            @options[:infile] = f
          end

          opts.on("-i", "--include INCLUDE", "name of the feature to include (default EC2Enhanced)") do |inc|
            config[:include] = inc
          end

          opts.on("-s", "--save", "save configuration to a file.  The file will be named after the route name") do
            @options[:save] = true
          end
        end
      end
    end

    class AddEc2eRoute < Command
      include Ec2eArgs
      include Ec2eFeatureOpts
      include Ec2eOptions

      def self.opname
        "add-ec2e-route"
      end
    
      def self.description
        "Add a route to be used with condor's EC2 Enhanced to the store"
      end
    
      def act
        keys = @fdata.keys.empty? ? name : @fdata.keys
        keys.each do |k|
          config[:name] = k
          cmd_args.each do |a|
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
      include Ec2eFeatureOpts

      def self.opname
        "add-ec2e-routes-to-group"
      end
    
      def self.description
        "Add EC2 Enhanced routes to a group"
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
      include Ec2eFeatureOpts

      def self.opname
        "add-ec2e-routes-to-node"
      end
    
      def self.description
        "Add EC2 Enhanced routes to a node"
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
      include Ec2eFeatureOpts

      def self.opname
        "replace-ec2e-routes-on-group"
      end
    
      def self.description
        "Replace EC2 Enhanced routes on a group"
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
      include Ec2eFeatureOpts

      def self.opname
        "replace-ec2e-routes-on-node"
      end
    
      def self.description
        "Replace EC2 Enhanced routes on a node"
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
      include Ec2eFeatureOpts
      include Ec2eOptions

      def self.opname
        "modify-ec2e-route"
      end
    
      def self.description
        "Modify an EC2 Enhanced route in the store"
      end
    
      def parse_args(*args)
        exit!(1, "incorrect number of args") if args.count < 2
        config[:name] = args.shift
        args.each do |arg|
          nvp = arg.split('=', 2)
          exit!(1, "#{nvp[0]} is not a valid option") if not cmd_args.include?(nvp[0].downcase)
          config[nvp[0].downcase.to_sym] = nvp[1].downcase
        end
        read_file
      end

      def act
        bad = store.checkFeatureValidity([prefix+name]).collect {|n| n.gsub(/#{prefix}/, '')}
        exit!(1, "route #{bad.join(', ')} does not exist") if bad != []
        feature = store.getFeature(prefix+name)
        route = feature.parameters["JOB_ROUTER_ENTRIES"]

        cmd_args.each do |a|
          if self.send(a) == nil
            route =~ /#{a.to_s.gsub(/_/, '')}[\w ]*=\s*"*([^;]+)"*/
            config[a.to_sym] = $1 if $1
          end
        end
        feature.modifyParams("ADD", {"JOB_ROUTER_ENTRIES"=>"$(JOB_ROUTER_ENTRIES)#{form_route}"}, {})
        return 0
      end
    end

    class RemoveEc2eRoute < Command
      include Ec2eFeatureOpts

      def self.opname
        "remove-ec2e-route"
      end
    
      def self.description
        "Remove an EC2 Enhanced route from the store"
      end
    
      register_callback :after_option_parsing, :parse_args
      def parse_args(*args)
        exit!(1, "incorrect number of arguments") if args.size < 1

        @routes = args.collect {|n| prefix + n}
      end

      def act
        bad = store.checkFeatureValidity(@routes).collect {|n| n.gsub(/#{prefix}/, '')}
        exit!(1, "route(s) #{bad.join(', ')} do not exist") if bad != []
puts @routes.inspect
        store.removeFeature(@routes)
        return 0
      end
    end
  end
end
