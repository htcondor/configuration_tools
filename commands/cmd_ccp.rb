# cmd_ccp.rb: apply condor configurations to nodes/groups
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
require 'condor_wallaby/utils'
require 'mrg/grid/config/shell'

module Mrg
  module Grid
    module Config
      module Shell
        module CCPOps
          include ToolUtils

          def remove_fields(klass)
            ToolUtils.remove_fields + [:annotation]
          end

          def valid_actions
            [action]
          end

          def init_option_parser
            @options = {}
            OptionParser.new do |opts|
              opts.banner = "Usage:  wallaby #{self.class.opname} TARGET FEATURE PARAM\n#{self.class.description}"
        
              opts.on("-h", "--help", "displays this message") do
                puts @oparser
                exit
              end

              opts.on("--schedds", "Prompt for scheduler information") do
                @options[:schedds] = true
              end

              opts.on("--qmf", "Prompt for QMF broker information") do
                @options[:qmf] = true
              end

              opts.on("-v", "--verbose", "Print more information, if available") do
                @options[:verbose] = true
              end
            end
          end

          def entities_needed
            not (@options.has_key?(:schedds) || @options.has_key?(:qmf))
          end

          def parse_args(*args)
            @cmds = []

            # Retrieve the target
            has_target = false
            args.each {|a| has_target = has_target || a.downcase.include?("group=") || a.downcase.include?("node=")}
            exit!(1, "No target specified.  Exiting") if not has_target
            t = args.shift.split('=', 2)
            if store.send("check#{t[0].downcase.capitalize}Validity", [t[1]]) != []
              exit!(1, "failed to find #{t[0].downcase} \"#{t[1]}\"")
            end
            @target = {t[0].downcase.capitalize.to_sym => t[1]}

            exit!(1, "No configuration entities specified.  Exiting") if entities_needed && args.size < 1
            args.each do |arg|
              as = arg.split('=', 2)

              # Retrieve the set of this type of entity and add to it
              ent_list = self.send("#{action}_#{as[0].downcase}s")
              ent_list[as[1]] = nil if ent_list.instance_of?(Hash)
              ent_list.push(as[1]) if ent_list.instance_of?(Array)
            end
          end

          def self.included(receiver)
            if receiver.respond_to?(:register_callback)
              receiver.register_callback :after_option_parsing, :parse_args
            end
          end

          def save_snapshot_cmds(name="")
            [Mrg::Grid::Config::Shell::MakeSnapshot, [name]]
          end

          def activate_cmds
            [Mrg::Grid::Config::Shell::Activate, []]
          end

          def target_obj
            if @target.has_key?(:Group)
              @obj ||= store.getGroupByName(@target[:Group])
            else
              @obj ||= store.getNode(@target[:Node]).identity_group
            end
          end

          def add_parameters
            @padded ||= {}
          end
 
          def remove_parameters
            @premoved ||= {}
          end

          def finalize_params
            nil
          end

          def add_features
            @fadded ||= []
          end
 
          def remove_features
            @fremoved ||= []
          end

          def finalize_features
            nil
          end

          def edit_target
            nil
          end

          def ws_prefix(act)
            act.to_s.capitalize.to_sym
          end

          def hashify(list)
            result = {}
            list.flatten.each {|n| result[n] = nil}
            result
          end

          def get_param_values
            add_parameters.keys.each do |pname|
              print "Value for \"#{pname}\": "
              add_parameters[pname] = STDIN.gets.strip
            end
          end

          def config_node_schedulers
            return if not @options.has_key?(:schedds)
            if action == :remove
              remove_parameters["SCHEDD_NAME"] = nil
              remove_parameters["SCHEDD_HOST"] = nil
            else
              print "Enter the name of the default scheduler: "
              name = STDIN.gets.strip
              print "Is this a High Available Scheduler [y/N] ? "
              if STDIN.gets.downcase.strip == 'y'
                add_parameters["SCHEDD_NAME"] = name
                remove_parameters["SCHEDD_HOST"] = nil
              else
                remove_parameters["SCHEDD_NAME"] = nil
                add_parameters["SCHEDD_HOST"] = name
              end
            end
          end

          def config_qmf_broker
            return if not @options.has_key?(:qmf)
            if action == :remove
              remove_parameters["QMF_BROKER_HOST"] = nil
              remove_parameters["QMF_BROKER_PORT"] = nil
            else
              print "Enter the hostname of the AMQP broker this group will use to communicate with the Management Console: "
              add_parameters["QMF_BROKER_HOST"] = STDIN.gets.strip

              valid = false
              while not valid
                print "Enter the port the AMQP broker listens on: "
                num = STDIN.gets.strip
                break if num.empty?
                valid = Integer(num) rescue false
                if valid
                  add_parameters["QMF_BROKER_PORT"] = num
                else
                  puts "Error: \"#{num}\" is not a valid port"
                end
              end
            end
          end

          def apply?
            puts
            print "Apply these changes [Y/n] ? "
            STDIN.gets.downcase.strip != 'n'
          end

          def check_add_params_needed
            p_on_target = target_obj.getConfig

            # Check for special case parameters

            # EC2 Enhanced
            if (p_on_target.keys.include?("NEED_SET_EC2E_ROUTES") && p_on_target["NEED_SET_EC2E_ROUTES"].downcase == "true") || (add_features.include?("EC2Enhanced")) || (add_parameters.keys.include?("NEED_SET_EC2E_ROUTES") && add_parameters["NEED_SET_EC2E_ROUTES"].downcase == "true")
              route_data = [["Name of the route", :Name],
                            ["Route requirements", :requirements],
                            ["Amazon Instance Type", :set_amazoninstancetype],
                            ["Filename containing an AWS Public Key for this route", :set_amazonpublickey],
                            ["Filename containing an AWS Private Key for this route", :set_amazonprivatekey],
                            ["Filename containing an AWS Access Key for this route", :set_amazonaccesskey],
                            ["Filename containing an AWS Secret Key for this route", :set_amazonsecretkey],
                            ["Filename containing an RSA Public Key for this route", :set_rsapublickey],
                            ["S3 Storage Bucket name for this route", :set_amazons3bucketname],
                            ["SQS Queue name for this route", :set_amazonsqsqueuename],
                            ["AMI ID for use with this route", :set_amazonamiid]
                           ]
              base_route = "$(JOB_ROUTER_ENTRIES)"
              routes = ""
              continue = false
              begin
                print "Configure #{continue ? "another" : "an"} EC2Enhanced Route [y/N] ? "
                continue = (STDIN.gets.strip == 'y')
                if continue
                  routes += " [ GridResource = \"condor localhost $(COLLECTOR_HOST)\";"
                  route_data.each do |prompt, name|
                    print "#{prompt}: "
                    quote = '"' unless name == :requirements
                    routes += " #{name} = #{quote}#{STDIN.gets.strip}#{quote};"
                  end
                  routes += " set_remote_jobuniverse = 5; ]"
                end
              end while continue
              add_parameters["JOB_ROUTER_ENTRIES"] = base_route + routes
              add_parameters["NEED_SET_EC2E_ROUTES"] = (routes.empty? ? "TRUE" : "FALSE")
            end

            # VM Universe
            if add_features.include?("VMUniverse")
              vm_types = ["xen", "kvm"]
              begin
                print "Type of Virtual Machines to run on this node (xen or kvm): "
                type = STDIN.gets.strip
                puts "Error: \"#{type}\" is not a valid Virtual Machine type.  Please try again" if not vm_types.include?(type)
              end while not vm_types.include?(type)
              add_parameters["VM_TYPE"] = type
              add_parameters["XEN_BOOTLOADER"] = "/usr/bin/pygrub" if type.downcase == "xen"
              remove_parameters["XEN_BOOTLOADER"] = nil if type.downcase != "xen"

              # Networking params
              print "Enable networking in the VM universe [y/N] ? "
              enabled = (STDIN.gets.strip.downcase == 'y')
              add_parameters["VM_NETWORKING"] = (enabled ? "TRUE" : "FALSE")
              if enabled
                vm_net_types = {:nat=>"nat", :bridge=>"bridge", :both=>"nat, bridge"}
                type = ""
                begin
                  print "Supported VM networking type (#{vm_net_types.keys.join(', ')}): "
                  type = STDIN.gets.strip.to_sym
                  puts "Invalid VM networking type \"#{type}\"" if not vm_net_types.keys.include?(type)
                end while not vm_net_types.keys.include?(type)
                add_parameters["VM_NETWORKING_TYPE"] = vm_net_types[type]
                remove_parameters["VM_NETWORKING_DEFAULT_TYPE"] = nil if type != :both
                if type != :nat
                  print "Networking interface for bridge networking: "
                  add_parameters["VM_NETWORKING_BRIDGE_INTERFACE"] = STDIN.gets.strip
                end

                if type == :both
                  vm_net_types.delete(:both)
                  begin
                    print "Default VM networking type (#{vm_net_types.keys.join(', ')}): "
                    type = STDIN.gets.strip
                    type = type.to_sym if not type.empty?
                    puts "\"#{type}\" is an invalid default VM networking type" if not vm_net_types.keys.include?(type)
                  end while not vm_net_types.keys.include?(type)
                  add_parameters["VM_NETWORKING_DEFAULT_TYPE"] = vm_net_types[type]
                end
              else
                remove_parameters["VM_NETWORKING_TYPE"] = nil
                remove_parameters["VM_NETWORKING_DEFAULT_TYPE"] = nil
                remove_parameters["VM_NETWORKING_BRIDGE_INTERFACE"] = nil
              end
            end

            # Prompt the user if there are still parameters that need to be set
            missing = get_unique_mustchange_params(add_features) - add_parameters.keys
            if missing.size > 0
              puts "The following parameters need to be set for this configuration to be valid:"
              missing.sort.each {|p| puts p}
              print "Set these parameters now ? [y/N] "
              if STDIN.gets.strip.downcase == 'y'
                missing.sort.each do |param|
                  if not add_parameters.include?(p)
                    print "#{param}: "
                    value = STDIN.gets.strip
                    if value.empty?
                      print "Use a value for \"#{param}\" defined elsewhere in the pool configuration? [Y/n] "
                      if STDIN.gets.strip.downcase != 'n'
                        puts "Adding a parameter that uses a default value is not permitted.  This parameter change will be discarded"
                        next
                      end
                    end
                    add_parameters[param] = value
                  end
                end
              else
                puts "Electing not to set these parameters now"
                puts "WARNING: This configuration may not be able to be activated"
              end
            end
          end

          def ec2enhanced_params
            ["NEED_SET_EC2E_ROUTES"]
          end

          def vmuniverse_params
            ["XEN_BOOTLOADER", "VM_NETWORKING_TYPE",
             "VM_NETWORKING_DEFAULT_TYPE", "VM_NETWORKING_BRIDGE_INTERFACE"]
          end

          def check_remove_params_needed
            remove_parameters.merge!(hashify(get_unique_mustchange_params(remove_features)))

            ["EC2Enhanced", "VMUniverse"].each do |fn|
              if remove_features.include?(fn)
                self.send("#{fn.downcase}_params").each do |p|
                  remove_parameters[p] = nil
                end
              end
            end
          end

          def get_unique_mustchange_params(list)
            unique = []
            candidates = []
            mustchange = store.getMustChangeParams

            # Iterate over the provided list of features and check each
            # to see if they include parameters that are using default values.
            list.each do |f|
              params_on_feature = store.getFeature(f).explain

              # For each list of parameters on the feature, check to see if
              # the list contains any MustChange parameters.  This is done by
              # checking if the parameter must be provided a value by the user
              # and seeing if the parameter on the feature is set to use the
              # default value.  If it is, that means the parameter hasn't
              # been given a value.
              params_on_feature.keys.each {|p| candidates.push(p) if mustchange.keys.include?(p) && params_on_feature[p]['how'] == "set-to-default"}
            end

            # Retrieve all the features already configured on the target
            # and see if those features contain must change parameters that
            # need explicitly set values.  These are must change params that
            # need values provided by the user.
            mc_wo_values = []
            target_obj.features.each do |f|
              if not list.include?(f)
                pof = store.getFeature(f).explain
                pof.keys.each {|p| mc_wo_values.push(p) if mustchange.keys.include?(p) && pof[p]['how'] == "set-to-default" && (not mc_wo_values.include?(p))}
              end
            end

            # Look through the candidate parameters and compare them against
            # the must change parameters set by the features already configured
            # on the target.
            # If a candidate parameter isn't given a value by another feature
            # on the target, then add it to the unique must change parameter
            # set
            candidates.each {|p| unique.push(p) if (not mc_wo_values.include?(p)) && (not unique.include?(p))}
            unique
          end

          def act
            edit_target

            if add_features.include?("ConsoleCollector")
              puts
              puts "WARNING: The ConsoleCollector feature should be applied to only "
              puts "         1 node in the pool.  Applying the ConsoleCollector"
              puts "         feature to more than node (or a group of nodes) in the"
              puts "         pool can cause dupliate information in the console."
              print "Continue adding the ConsoleCollector feature? [y/N] "
              add_features.delete("ConsoleCollector") if STDIN.gets.strip.downcase != 'y'
            end

            get_param_values
            config_node_schedulers
            config_qmf_broker
            check_add_params_needed
            check_remove_params_needed

            return 0 if not apply?

            finalize_params
            finalize_features
            valid_actions.each do |act|
              # Modify the features
              prefix = ws_prefix(act)
              if (not self.send("#{act}_features").empty?) || prefix == :Replace
                c = Mrg::Grid::Config::Shell.constants.grep(/#{prefix}#{@target.keys}Feature$/).to_s
                @cmds.push([Mrg::Grid::Config::Shell.const_get(c), [@target.values.to_s] + self.send("#{act}_features")])
              end

              # Modify the parameters
              if (not self.send("#{act}_parameters").empty?) || prefix == :Replace
                c = Mrg::Grid::Config::Shell.constants.grep(/#{prefix}#{@target.keys}Param$/).to_s
                @cmds.push([Mrg::Grid::Config::Shell.const_get(c), [@target.values.to_s] + params_as_array(self.send("#{act}_parameters"))])
              end
            end

            begin
              print "Create a named snapshot of this configuration [y/N] ? "
              continue = (STDIN.gets.strip.downcase == 'y')
              if continue
                print "  Snapshot Name: "
                name = STDIN.gets.strip
                puts "Invalid snapshot name" if name.empty?
              end
            end while continue && name.empty?
            if name && (not name.empty?)
              @cmds.push(save_snapshot_cmds(name))
            end

            print "Activate the changes [y/N] ? "
            if STDIN.gets.strip.downcase == 'y'
              @cmds.push(activate_cmds)
              @cmds.push(save_snapshot_cmds) if (not name) || name.empty?
            end

            run_wscmds(@cmds)
            return 0
          end
        end

        class CCPAdd < ::Mrg::Grid::Config::Shell::Command
          include CCPOps

          def self.opname
            "ccp-add"
          end
        
          def self.description
            "Append to the group/node with lowest priority"
          end

          def valid_actions
            [:add, :remove]
          end
        end

        class CCPRemove < ::Mrg::Grid::Config::Shell::Command
          include CCPOps

          def self.opname
            "ccp-remove"
          end
        
          def self.description
            "Remove from the group/node"
          end
        end

        class CCPInsert < ::Mrg::Grid::Config::Shell::Command
          include CCPOps

          def self.opname
            "ccp-insert"
          end
        
          def self.description
            "Insert into the group/node with highest priority"
          end

          def finalize_params
            add_parameters.replace(target_obj.params.merge(add_parameters))
          end

          def finalize_features
            add_features.push(target_obj.features).flatten!.uniq!
          end

          def ws_prefix(act)
            :Replace
          end

          def action
            :add
          end
        end

        class CCPList < ::Mrg::Grid::Config::Shell::Command
          include CCPOps

          def self.opname
            "ccp-list"
          end
        
          def self.description
            "List detailed information for a group or node in the store"
          end

          def entities_needed
            false
          end

          def act
            type, name = @target.shift
            c = Mrg::Grid::Config::Shell.constants.grep(/Show#{type.to_s[0,4].capitalize}[a-z]*$/).to_s
            @cmds.push([Mrg::Grid::Config::Shell.const_get(c), [name]])

            if @options.has_key?(:verbose) && type == :Node
              @cmds.push([Mrg::Grid::Config::Shell::ShowNodeConfig, [name]])
            end

            run_wscmds(@cmds)
            return 0
          end
        end

        class CCPEdit < ::Mrg::Grid::Config::Shell::Command
          include CCPOps

          def self.opname
            "ccp-edit"
          end
        
          def self.description
            "Edit the group/node"
          end

          def ws_prefix(act)
            :Replace
          end

          def group_obj
            klass = Mrg::Grid::SerializedConfigs::Group
            remove_fields("Group").each do |f|
              klass.saved_fields.delete(f)
            end
            group = klass.new
            group.name = @target.values.to_s
            group.features = target_obj.features
            group.params = target_obj.params
            group
          end

          def serialize
            @serialized ||= group_obj
          end

          def finalize_params
            edit_parameters.merge!(add_parameters)
          end

          def edit_parameters
            @eparams ||= {}
          end

          def edit_features
            @efeatures ||= []
          end

          def entities_needed
            false
          end

          def edit_target
            warnings = [[:Feature, "list of features"],
                        [:Parameter, "list of parameters"],
                        [:schedds, "request to prompt for schedd information"],
                        [:qmf, "request to prompt for broker information"]
                       ]
            warnings.each do |key, txt|
              f = "#{action}_#{key.to_s.downcase}s"
              ents = self.send(f) if self.respond_to?(f)
              puts "Warning: Ignoring #{txt} in edit mode" if @options.has_key?(key) || (ents && (not ents.empty?))
              @options.delete(key)
              ents.delete(key) if ents
            end

            edited = run_editor
            p = edited.params.select{|k, v| (not target_obj.params.keys.include?(k)) || ([k, v] != [k, target_obj.params[k]])}
            add_parameters.replace((p.empty? ? {} : Hash[*p.flatten]))
            p = target_obj.params.select{|k, v| (not edited.params.keys.include?(k))}
            remove_parameters.replace(p.empty? ? {} : Hash[*p.flatten])
            add_features.replace(edited.features.select{|n| (not target_obj.features.include?(n))})
            remove_features.replace(target_obj.features.select{|n| (not edited.features.include?(n))})
            edit_parameters.replace(edited.params)
            edit_features.replace(edited.features)
          end
        end
      end
    end
  end
end
