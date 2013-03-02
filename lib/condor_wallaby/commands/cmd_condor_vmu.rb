# cmd_condor_vmu.rb:  
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
    class AddCondorVmuFeature < Command
      def self.opname
        "add-condor-vmu-feature"
      end
    
      def self.description
        "Add a feature that configures condor's Virtual Machine Universe to the store"
      end
    
      def get_env(n)
        return ENV[n].to_sym if ENV.keys.include?(n)
        nil
      end

      def fdata(arg)
        @fdata.keys.include?(name) ? fdata[name][arg] : nil
      end

      def type
        @config[:type] || fdata(:type) || get_env("CONDOR_VMU_TYPE") || :kvm
      end

      def name
        @config[:name] || ENV["CONDOR_VMU_NAME"] || ""
      end

      def include
        @config[:include] || fdata(:include) || "VMUniverse"
      end

      def network
        @config[:network] || fdata(:network) || get_env('CONDOR_VMU_NETWORK') || :false
      end

      def net_type
        @config[:net_type] || fdata(:net_type) || get_env('CONDOR_VMU_NETWORK_TYPE') || nil
      end

      def net_default
        @config[:net_default] || fdata(:net_default) || get_env('CONDOR_VMU_NETWORK_DEFAULT') || nil
      end

      def net_bridge
        @config[:net_bridge] || fdata(:net_bridge) || get_env('CONDOR_VMU_NETWORK_BRIDGE') || nil
      end

      def cmd_args
        ["network", "net_type", "net_default", "net_bridge"]
      end

      def config
        @config ||= {}
      end

      def vm_types
        [:xen, :kvm]
      end

      def init_option_parser
        @config = {}
        @options = {}
        OptionParser.new do |opts|
          opts.banner = "Usage:  wallaby #{self.class.opname} [OPTIONS] ARG=VALUE ...\n#{self.class.description}"
    
          opts.on("-h", "--help", "displays this message") do
            puts @oparser
            exit
          end

          opts.on("-f", "--file INFILE", "read feature data from INFILE.  If provided, arguments provided on the command line will be ignored") do |f|
            @options[:infile] = f
          end

          opts.on("-i", "--include INCLUDE", "name of the feature to include (default VMUniverse)") do |inc|
            @config[:include] = inc
          end

          opts.on("-s", "--save", "save configuration to a file.  The file will be named after the feature") do
            @options[:save] = true
          end

          opts.on("-t", "--type TYPE", "type of VM to support (default kvm)") do |type|
            t = type.downcase.to_sym
            exit!(1, "#{t} is not a supported VM type.  Supported types are #{vm_types.join(',')}") if not vm_types.include?(t)
            @config[:type] = t
          end
        end
      end

      register_callback :after_option_parsing, :parse_args

      def read_file
        @fdata = {}
        if @options.has_key?(:infile)
          exit!(1, "#{@options[:infile]} no such file") if not File.exist?(@options[:infile])
          @fdata = ConfigParser.parse(File.read(@options[:infile]))
        end
      end

      def parse_args(*args)
        exit!(1, "you must specify a name for the feature") if args.size < 1 && (name.empty? && (not @options.has_key?(:infile)))
        @config[:name] = args.shift if args.count > 0 && (not @options.has_key?(:infile))
        args.each do |arg|
          nvp = arg.split('=', 2)
          exit!(1, "#{nvp[0]} is not a valid option") if not cmd_args.include?(nvp[0].downcase)
          @config[nvp[0].downcase.to_sym] = nvp[1].downcase
        end
        read_file
      end

      def type_args
        args = {}
        args["VM_TYPE"] = type
        args["XEN_BOOTLOADER"] = "/usr/bin/pygrub" if type == "xen"
        args
      end

      def net_args
        args = {}
        args["VM_NETWORKING"] = ["true", "false"].include?(network) ? network.to_s.upcase : "FALSE"
        if network == "true"
          ntypes = ["nat", "bridge", "both"]
          exit!(1, "you must provide a networking type if networking is enabled") if not net_type
          exit!(1, "#{net_type} is an invalid networking type.  Valid types are #{ntypes.join(',')}") if not ntypes.include?(net_type)
          args["VM_NETWORKING_TYPE"] = net_type

          # Default networking type
          if net_type == "both"
            dtypes = ntypes - ["both"]
            exit!(1, "you must provide a networking default type is networking type is both") if not net_default
            exit!(1, "#{net_default} is an invalid default networking type.  Valid types are #{dtypes.join(',')}") if not dtypes.include?(net_default)
            args["VM_NETWORKING_DEFAULT_TYPE"] = net_default
          end

          # Bridge network interface
          if net_type != "nat"
            exit!(1, "you must provide a bridge network adapter if bridged networking is to be used") if not net_bridge
            args["VM_NETWORKING_BRIDGE_INTERFACE"] = net_bridge
          end
        end
        args
      end

      def act
        keys = @fdata.keys.empty? ? name : @fdata.keys
        keys.each do |k|
          @config[:name] = k
          tf = Tempfile.new("vmu_config")
          tf.write("#name #{name}\n")
          tf.write("#includes #{include}\n")
          type_args.merge(net_args).each_pair do |n, v|
            tf.write("#{n} = #{v}\n")
          end
          tf.close
          Mrg::Grid::Config::Shell::FeatureImport.new(store, "").main([tf.path])
          FileUtils.cp(tf.path, "#{name}.feature") if @options.has_key?(:save)
          tf.unlink
        end
        return 0
      end
    end
  end
end
