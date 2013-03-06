# cmd_condor_vmu.rb: Commands for configuring condor's Vitual Machine Universe
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
    class AddVmuFeature < Command

      def self.opname
        "add-vmu-feature"
      end
    
      def self.description
        "Add a feature that configures condor's Virtual Machine Universe to the store."
      end

      def self.cmd_args
        ["network", "network-type", "network-default", "network-bridge"]
      end

      include CommandArgs
      include CommandOptions
    
      def type
        config[:type] || fdata(:type) || get_env("CONDOR_VMU_TYPE") || :kvm
      end

      def def_include
        "VMUniverse"
      end

      def noun
        "feature"
      end

      def env_prefix
        "CONDOR_VMU"
      end

      def vm_types
        [:xen, :kvm]
      end


      def extra_options(o)
        o.on("-t", "--type TYPE", "type of VM to support (default kvm)") do |type|
          t = type.downcase.to_sym
          exit!(1, "#{t} is not a supported VM type.  Supported types are #{vm_types.join(',')}") if not vm_types.include?(t)
          config[:type] = t
        end
      end

      def type_args
        args = {}
        args["VM_TYPE"] = type
        args["XEN_BOOTLOADER"] = "/usr/bin/pygrub" if type == :xen
        args
      end

      def net_args
        args = {}
        args["VM_NETWORKING"] = (network && ["TRUE", "FALSE"].include?(network.to_s.upcase)) ? network.to_s.upcase : "FALSE"
        if network && network.to_s.upcase == "TRUE"
          ntypes = ["nat", "bridge"]
          exit!(1, "you must provide a networking type if networking is enabled") if not network_type
          network_type.split(',').each {|t| exit!(1, "#{network_type} is an invalid networking type.  Valid types are #{ntypes.join(',')}") if not ntypes.include?(t.downcase)}
          args["VM_NETWORKING_TYPE"] = network_type

          # Default networking type
          if network_type.split(',').count > 1
            exit!(1, "you must provide a networking default type if more than 1 networking type is defined") if not network_default
            exit!(1, "#{network_default} is an invalid default networking type.  Valid types are #{dtypes.join(',')}") if not ntypes.include?(network_default.downcase)
            args["VM_NETWORKING_DEFAULT_TYPE"] = network_default
          end

          # Bridge network interface
          if network_type.include?("bridge")
            exit!(1, "you must provide a bridge network adapter if bridged networking is to be used") if not network_bridge
            args["VM_NETWORKING_BRIDGE_INTERFACE"] = network_bridge
          end
        end
        args
      end

      def act
        keys = @fdata.keys.empty? ? name : @fdata.keys
        keys.each do |k|
          config[:name] = k
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
