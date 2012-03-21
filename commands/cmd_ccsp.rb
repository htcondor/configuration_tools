# cmd_ccs.rb:  
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

module Mrg
  module Grid
    module SerializedConfigs
      class GroupMembership
        include DefaultStruct
        field :name, String
        field :members, Set
      end
    end

    module Config
      module Shell
        module UXOps
          def get_param_values
            @entities[:Parameter].each do |pname|
              print "Value for \"#{pname}\": "
              @entities[:Parameter][pname] = gets.strip
            end
          end

          def config_node_schedulers
            return if not @options.has_key?(:schedds)
            if action == "delete"
              @entities[:Parameter]["SCHEDD_NAME"] = nil
              @entities[:Parameter]["SCHEDD_HOST"] = nil
            else
              print "Enter the name of the default scheduler: "
              name = gets.strip
              print "Is this a High Available Scheduler [y/N] ? "
              if gets.downcase.strip == 'y'
                @entities[:Parameter]["SCHEDD_NAME"] = name
                @entities[:Parameter]["SCHEDD_HOST"] = nil
              else
                @entities[:Parameter]["SCHEDD_NAME"] = nil
                @entities[:Parameter]["SCHEDD_HOST"] = name
              end
            end
          end

          def config_qmf_broker
            return if not @options.has_key?(:qmf)
            if action == "delete"
              @entities[:Parameter]["QMF_BROKER_HOST"] = nil
              @entities[:Parameter]["QMF_BROKER_PORT"] = nil
            else
              print "Enter the hostname of the AMQP broker this group will use to communicate with the Management Console: "
              @entities[:Parameter]["QMF_BROKER_HOST"] = gets.strip

              valid = false
              while not valid
                print "Enter the port the AMQP broker listens on: "
                num = gets.strip
                valid = Integer(num) rescue false
                if valid
                  @entities[:Parameter]["QMF_BROKER_PORT"] = num
                else
                  puts "Error: \"#{num}\" is not a valid port"
                end
              end
            end
          end

          def apply?
            puts
            print "Apply these changes [Y/n] ? "
            gets.downcase.strip != 'n'
          end
        end

        module CommonOps
          def run_wscmds
            @cmds.compact!
            @cmds.each do |cmdset|
              exit(1) if cmdset[0].new(store, "").main(cmdset[1].flatten) != 0
            end
          end

          def run_cmdline(cmd)
            pid = Process.fork()
            if pid == nil
              exec(cmd)
            else
              Process.waitpid(pid, 0)
            end
          end

          def cmd_prefix
            @cprefix ||= self.class.opname.split("-")[0].to_sym
          end

          def yaml_file
            @file ||= Tempfile.new(cmd_prefix)
          end

          def run_editor
            @editor ||= ENV['EDITOR'] || "/bin/vi"
            yaml_file.seek(0, IO::SEEK_SET)
            yaml_file.truncate(0)
            yaml_file.write(serialize.to_yaml)
            yaml_file.flush
            run_cmdline("#{@editor} #{yaml_file.path}")
            yaml_file.flush
            yaml_file.seek(0, IO::SEEK_SET)
            YAML::parse(yaml_file.read).transform
          end

        end

        module CCPOps
          def action
            @action ||= self.class.opname.split("-")[1].to_sym
          end

          def params_as_array(phash)
            list = []
            phash.each_pair do |k, v|
              list.push("#{k}=#{v}") if v
              list.push(k) if not v
            end
            list
          end

          def change_action(new)
            return if new == @action
            @orig_action = action
            @action = new
          end

          def reset_action
            @action = @orig_action if @orig_action
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
            end
          end

          def new_feature_type
            []
          end

          def new_parameter_type
            {}
          end

          def min_args
            2
          end

          def parse_args(*args)
            @cmds = []
            if args.size < min_args
              exit!(1, "Incorrect number of arguments")
            end

            # Retrieve the target
            @target = {}
            t = args.shift.split('=', 2)
            @target[t[0].to_sym] = t[1]

            @entities = Hash.new {|h,k| h[k] = Hash.new {|h1,k1| h1[k1] = nil}}
            args.each do |arg|
              as = arg.split('=', 2)
              type = as[0].to_sym
              if not @entities[action].has_key?(type)
                @entities[action][type] = self.send("new_#{type.to_s.downcase}_type")
              end
              @entities[action][type][as[1]] = nil if @entities[action][type].instance_of?(Hash)
              @entities[action][type].push(as[1]) if @entities[action][type].instance_of?(Array)
            end
puts "Entities: #{@entities.inspect}"
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

          def add_param(name, value)
            add_params[name] = value
            unique_params.delete(name)
          end

          def unique_params
            @uniques ||= {}
            @uniques[action] ||= get_unique_mustchange_params
          end

          def params
            self.send("#{action}_params")
          end

          def add_params
            @entities[:add][:Parameter] ||= {}
#            @entities[action][:Parameter] ||= {}
          end
 
          def remove_params
            @entities[:remove][:Parameter] ||= {}
          end

          def finalize_params
            nil
          end

          def features
            self.send("#{action}_features")
          end

          def add_features
            @entities[:add][:Feature] ||= []
          end
 
          def remove_features
            @entities[:remove][:Feature] ||= []
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
            Hash[list.flatten.map {|n| [n, nil]}]
          end

          def check_add_params_needed
            change_action(:add)
            p_on_target = target_obj.getConfig

            # Check for special case parameters

            # EC2 Enhanced
            if (p_on_target.keys.include?("NEED_SET_EC2E_ROUTES") && p_on_target["NEED_SET_EC2E_ROUTES"].downcase == "true") || (add_features.include?("EC2Enhanced")) || (params.keys.include?("NEED_SET_EC2E_ROUTES") && params["NEED_SET_EC2E_ROUTES"].downcase == "true")
              route_data = [["Name of the route", "Name"],
                            ["Route requirements", "requirements"],
                            ["Amazon Instance Type", "set_amazoninstancetype"],
                            ["Filename containing an AWS Public Key for this route", "set_amazonpublickey"],
                            ["Filename containing an AWS Private Key for this route", "set_amazonprivatekey"],
                            ["Filename containing an AWS Access Key for this route", "set_amazonaccesskey"],
                            ["Filename containing an AWS Secret Key for this route", "set_amazonsecretkey"],
                            ["Filename containing an RSA Public Key for this route", "set_rsapublickey"],
                            ["S3 Storage Bucket name for this route", "set_amazons3bucketname"],
                            ["SQS Queue name for this route", "set_amazonsqsqueuename"],
                            ["AMI ID for use with this route", "set_amazonamiid"]
                           ]
              base_route = "$(JOB_ROUTER_ENTRIES)"
              routes = ""
              continue = false
              begin
                print "Configure #{continue ? "another" : "an"} EC2Enhanced Route [y/N] ? "
                continue = (gets.strip == 'y')
                if continue
                  routes += " [ GridResource = \"condor localhost $(COLLECTOR_HOST)\";"
                  route_data.each do |prompt, name|
                    print "#{prompt}: "
                    quote = "\"" if name == "requirements"
                    routes += " #{name} = #{quote}#{gets.strip}#{quote};"
                  end
                  routes += " set_remote_jobuniverse = 5; ]"
                end
              end while continue
              add_param("JOB_ROUTER_ENTRIES", base_route + routes)
              add_param("NEED_SET_EC2E_ROUTES", routes.empty?)
            end

            # VM Universe
            if add_features.include?("VMUniverse")
              vm_types = ["xen", "kvm"]
              begin
                print "Type of Virtual Machines to run on this node (xen or kvm): "
                type = gets.strip
                puts "Error: \"#{type}\" is not a valid Virtual Machine type.  Please try again" if not vm_types.include?(type)
              end while not vm_types.include?(type)
puts "before: #{unique_params.inspect}"
              add_param("VM_TYPE", type)
puts "after: #{unique_params.inspect}"
              add_param("XEN_BOOTLOADER", "/usr/bin/pygrub") if type.downcase == "xen"
              remove_params["XEN_BOOTLOADER"] = nil if type.downcase != "xen"

              # Networking params
              print "Enable networking in the VM universe [y/N] ? "
              enabled = (gets.strip.downcase == 'y')
              add_param("VM_NETWORKING", enabled)
              if enabled
                vm_net_types = {:nat=>"nat", :bridge=>"bridge", :both=>"nat, bridge"}
                type = ""
                begin
                  print "Supported VM networking type (#{vm_net_types.keys.join(', ')}): "
                  type = gets.strip.to_sym
                  puts "Invalid VM networking type \"#{type}\"" if not vm_net_types.keys.include?(type)
                end while not vm_net_types.keys.include?(type)
                add_param("VM_NETWORKING_TYPE", vm_net_types[type])
                remove_params["VM_NETWORKING_DEFAULT_TYPE"] = nil if type != :both
                if type == :both
                  vm_net_types.delete(:both)
                  begin
                    print "Default VM networking type (#{vm_net_types.keys.join(', ')}): "
                    type = gets.strip
                    type = type.to_sym if not type.empty?
                    puts "\"#{type}\" is an invalid default VM networking type" if not vm_net_types.keys.include?(type)
                  end while not vm_net_types.keys.include?(type)
                  add_param("VM_NETWORKING_DEFAULT_TYPE", vm_net_types[type])
                end
              else
                remove_params["VM_NETWORKING_TYPE"] = nil
                remove_params["VM_NETWORKING_DEFAULT_TYPE"] = nil
              end
            end

            # Prompt the user if there are still parameters that need to be set
puts "unique = #{unique_params.inspect}"
            if (unique_params - params.keys).size > 0
              puts "The following parameters need to be set for this configuration to be valid:"
              unique_params.sort.each {|p| puts p if not params.keys.include?(p)}
              print "Set these parameters now ? [y/N] "
              if gets.strip.downcase == 'y'
                unique_params.sort.each do |param|
                  if not params.include?(p)
                    print "#{param}: "
                    value = gets.strip
                    if value.empty?
                      print "Use a value for \"#{param}\" defined elsewhere in the pool configuration? [Y/n] "
                      if gets.strip.downcase != 'n'
                        puts "Adding a parameter that uses a default value is not permitted.  This parameter change will be discarded"
                        next
                      end
                    end
                    add_param(param, value)
                  end
                end
              else
                puts "Electing not to set these parameters now"
                puts "WARNING: This configuration may not be able to be activated"
              end
            end
            reset_action
          end

          def check_remove_params_needed
            change_action(:remove)
            remove_params.merge!(hashify(unique_params))

            special_params = ["NEED_SET_EC2E_ROUTES", "VM_TYPE",
                              "XEN_BOOTLOADER", "VM_NETWORKING",
                              "VM_NETWORKING_TYPE",
                              "VM_NETWORKING_DEFAULT_TYPE"]
            special_params.each do |p|
              remove_features.each do |f|
                fparams = store.getFeature(f).params
                remove_params[p] = nil if fparams.keys.include?(p)
              end
            end
            reset_action
          end

          def get_unique_mustchange_params
            unique = []
            candidates = []
            mustchange = store.getMustChangeParams

            # Iterate over the provided list of features and check each
            # to see they include parameters that are using default values.
            features.each do |f|
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
            # and see if those features contain must change parameteres that
            # have explicitly set values.  
            mc_w_values = []
            target_obj.features.each do |f|
              if not features.include?(f)
                pof = store.getFeature(f).explain
                pof.keys.each {|p| mc_w_values.push(p) if mustchange.keys.include?(p) && pof[p]['how'] == "set-explicitly"}
              end
            end

            # Look through the candidate parameters and compare them against
            # the must change parameters set by the features on the target.
            # If a candidate parameter isn't given a value by another feature
            # on the target, then add it to the unique must change parameter
            # set
            candidates.each {|p| unique.push(p) if not mc_w_values.include?(p)}
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
              features.delete("ConsoleCollector") if gets.strip.downcase != 'y'
            end

            config_node_schedulers
            config_qmf_broker
puts "add early: #{add_features.inspect}"
puts "entities before: #{@entities.inspect}"
            check_add_params_needed
            check_remove_params_needed
puts "entities after: #{@entities.inspect}"

            return 0 if not apply?

            finalize_params
            finalize_features
puts "before loop: #{add_features.inspect}"
            @entities.keys.each do |act|
#              change_action(act)
              # Modify the features
              prefix = ws_prefix(act)
puts "prefix: #{prefix.inspect}"
puts "act: #{act.inspect}"
puts "features: #{self.send("#{act}_features").inspect}"
              if (not self.send("#{act}_features").empty?) || prefix == :Replace
                c = Mrg::Grid::Config::Shell.constants.grep(/#{prefix}#{@target.keys}Feature$/).to_s
                @cmds.push([Mrg::Grid::Config::Shell.const_get(c), [@target.values.to_s] + self.send("#{act}_features")])
              end

              # Modify the parameters
puts "params: #{self.send("#{act}_params").inspect}"
              if (not self.send("#{act}_params").empty?) || prefix == :Replace
                c = Mrg::Grid::Config::Shell.constants.grep(/#{prefix}#{@target.keys}Param$/).to_s
                @cmds.push([Mrg::Grid::Config::Shell.const_get(c), [@target.values.to_s] + params_as_array(self.send("#{act}_params"))])
              end
#              reset_action
            end

            begin
              print "Create a named snapshot of this configuration [y/N] ? "
              continue = (gets.strip.downcase == 'y')
              if continue
                print "  Snapshot Name: "
                name = gets.strip
                puts "Invalid snapshot name" if name.empty?
              end
            end while continue && name.empty?
            if name && (not name.empty?)
              @cmds.push(save_snapshot_cmds(name))
            end

            print "Activate the changes [y/N] ? "
            if gets.strip.downcase == 'y'
              @cmds.push(activate_cmds)
              @cmds.push(save_snapshot_cmds) if (not name) || name.empty?
            end

puts @cmds.inspect
            run_wscmds
            return 0
          end
        end

        module CCSOps
          def init_option_parser
            OptionParser.new do |opts|
              opts.banner = "Usage:  wallaby #{self.class.opname} FILENAME [COMPARE_FILENAME]\n#{self.class.description}"
        
              opts.on("-h", "--help", "displays this message") do
                puts @oparser
                exit
              end
            end
          end

          def parse_args(*args)
            @cmds = []
            if args.size < 1
              exit!(1, "Incorrect number of arguments")
            end

            @entities = Hash.new {|h,k| h[k] = Hash.new {|h1,k1| h1[k1] = {}}}
            args.each do |arg|
              as = arg.split('=', 2)
              @entities[as[0].to_sym][as[1]] = nil
            end
          end

          def self.included(receiver)
            if receiver.respond_to?(:register_callback)
              receiver.register_callback :after_option_parsing, :parse_args
            end
          end
        
          def create_node_obj(name, obj=nil)
            node = Mrg::Grid::SerializedConfigs::Node.new
            node.name = name
            node.membership = (obj ? obj.memberships : [])
            node
          end

          def create_parameter_obj(name, obj=nil)
            param = Mrg::Grid::SerializedConfigs::Parameter.new
            param.name = name
            if obj != nil
              param.kind = obj.kind
              param.default_val = obj.default
              param.description = obj.description
              param.must_change = obj.must_change
              param.level = obj.visibility_level
              param.needs_restart = obj.requires_restart
            end
            param.conflicts = (obj ? obj.conflicts : [])
            param.depends = (obj ? obj.depends : [])
            param
          end

          def create_feature_obj(name, obj=nil)
            feature = Mrg::Grid::SerializedConfigs::Feature.new
            feature.name = name
            feature.params = (obj ? obj.params : {})
            feature.conflicts = (obj ? obj.conflicts : [])
            feature.depends = (obj ? obj.depends : [])
            feature.included = (obj ? obj.included_features : [])
            feature
          end

          def create_group_obj(name, obj=nil)
            group = Mrg::Grid::SerializedConfigs::GroupMembership.new
            group.name = name
            group.members = (obj ? obj.membership : [])
            group
          end

          def create_subsystem_obj(name, obj=nil)
            subsystem = Mrg::Grid::SerializedConfigs::Subsystem.new
            subsystem.name = name
            subsystem.params = (obj ? obj.params : [])
            subsystem
          end

          def update_node_cmds(name, obj)
            [Mrg::Grid::Config::Shell.const_get("ReplaceNodeMembership"), [name] + obj.membership]
          end

          def update_feature_cmds(name, obj)
            cmds = []
            params = []
            obj.params.each_pair {|k, v| params.push("#{k}=#{v}")}
            cmds.push([Mrg::Grid::Config::Shell.const_get("ReplaceFeatureParam"), [name] + params])
            cmds.push([Mrg::Grid::Config::Shell.const_get("ReplaceFeatureInclude"), [name] + obj.included])
            cmds.push([Mrg::Grid::Config::Shell.const_get("ReplaceFeatureConflict"), [name] + obj.conflicts])
            cmds.push([Mrg::Grid::Config::Shell.const_get("ReplaceFeatureDepend"), [name] + obj.depends])
            cmds
          end

          def update_parameter_cmds(name, obj)
            args = []
            args.push("--kind #{obj.kind}")
            args.push("--default-val \"#{obj.default_val}\"")
            args.push("--description \"#{obj.description}\"")
            args.push("--must-change #{obj.must_change}")
            args.push("--level #{obj.level}")
            args.push("--needs-restart #{obj.needs_restart}")
            cmds = [Mrg::Grid::Config::Shell.const_get("ModifyParam"), [name] + args]
            cmds.push([Mrg::Grid::Config::Shell.const_get("ReplaceParamConflict"), [name] + obj.conflicts])
            cmds.push([Mrg::Grid::Config::Shell.const_get("ReplaceParamDepend"), [name] + obj.depends])
            cmds
          end

          def update_subsystem_cmds(name, obj)
            [Mrg::Grid::Config::Shell.const_get("ReplaceSubsysParam"), [name] + obj.params]
          end

          def update_group_cmds(name, obj)
            cmds = []
            obj.members.each do |node|
              if @ogroups.has_key?(name) && (not @ogroups[name].members.include?(node))
                # Node was added
                cmds.push(Mrg::Grid::Config::Shell.const_get("AddNodeMembership"), [node, name])
              end
            end
            if @ogroups.has_key?(name)
              @ogroups[name].members.each do |node|
                if not obj.members.include?(node)
                  # Node was removed
                  cmds.push(Mrg::Grid::Config::Shell.const_get("RemoveNodeMembership"), [node, name])
                end
              end
            end
            cmds if not cmds.empty?
          end

          def compare_objs(obj1, obj2)
            (obj1.class == obj2.class) && (obj1.name == obj2.name)
          end

          def remove_invalid_entries(obj)
            # Generate the list of entity names the obj uses\
            if @invalids.has_key?(:Parameter)
              (obj.params.instance_of?(Hash) ? @invalids[:Parameter].each{|i| obj.params.delete(i)} : obj.params - @invalids[:Parameter]) if obj.respond_to?(:params)
              if obj.instance_of?(Mrg::Grid::SerializedConfigs::Parameter)
                obj.conflicts -= @invalids[:Parameter]
                obj.depends -= @invalids[:Parameter]
              end
            end
            if @invalids.has_key?(:Group)
              obj.membership -= @invalids[:Group] if obj.respond_to?(:membership)
            end
            if @invalids.has_key?(:Node)
              obj.members -= @invalids[:Node] if obj.respond_to?(:members)
            end
            if @invalids.has_key?(:Feature)
              obj.features -= @invalids[:Feature] if obj.respond_to?(:features)
              obj.included -= @invalids[:Feature] if obj.respond_to?(:included)
              if obj.instance_of?(Mrg::Grid::SerializedConfigs::Feature)
                obj.conflicts -= @invalids[:Feature]
                obj.depends -= @invalids[:Feature]
              end
            end

            obj
          end

          def verify_obj(obj)
            bad_names = {}
            names = {}

            # Generate the list of entity names the obj uses
            names[:Parameter] = obj.respond_to?(:params) ? (obj.params.instance_of?(Hash) ? obj.params.keys : obj.params) : []
            names[:Group] = obj.respond_to?(:membership) ? obj.membership : []
            names[:Node] = obj.respond_to?(:members) ? obj.members : []
            names[:Feature] = obj.respond_to?(:features) ? obj.features : []
            names[:Feature] += obj.respond_to?(:included) ? obj.included : []
            if obj.respond_to?(:conflicts)
              names[:Feature] += obj.conflicts if obj.instance_of?(Mrg::Grid::SerializedConfigs::Feature)
              names[:Parameter] += obj.conflicts if obj.instance_of?(Mrg::Grid::SerializedConfigs::Parameter)
            end
            if obj.respond_to?(:depends)
              names[:Feature] += obj.depends if obj.instance_of?(Mrg::Grid::SerializedConfigs::Feature)
              names[:Parameter] += obj.depends if obj.instance_of?(Mrg::Grid::SerializedConfigs::Parameter)
            end

            names.each_key do |t|
              list = []
              list = names[t]
              list -= @entities[t].keys if @entities.has_key?(t)
              bad = store.send("check#{t}Validity", list)
              bad_names[t] = bad if not bad.empty?
            end

            bad_names
          end

          def serialize
            list = []
            @entities.each_key do |type|
              list.push(@entities[type].values).flatten!
            end
            list
          end

          def sync_memberships
            if @entities.has_key?(:Node) && @entities.has_key?(:Group)
              @entities[:Node].each_pair do |node, n_obj|
                @entities[:Group].each_pair do |group, g_obj|
                  if (n_obj.membership.include?(group)) && (not g_obj.members.include?(node))
                    (@pre_edit.has_key?(:Group) && @pre_edit[:Group].has_key?(group) && @pre_edit[:Group][group].members.include?(node)) ? n_obj.membership -= [group] : g_obj.members.push(node)
                  elsif (g_obj.members.include?(node)) && (not n_obj.membership.include?(group))
                    (@pre_edit.has_key?(:Node) && @pre_edit[:Node].has_key?(node) && @pre_edit[:Node][node].membership.include?(group)) ? g_obj.members -= [node] : n_obj.membership.push(group)
                  end
                end
              end
            end
          end

          def get_type(klass_name)
            return "Group".to_sym if klass_name.to_s.split('::').last == "GroupMembership"
            klass_name.to_s.split('::').last.to_sym
          end

          def deep_copy(obj)
            YAML::parse(obj.to_yaml).transform
          end

          def edit_objs
            retry_loop = true

            # Dump the data into a file and open an editor
            while retry_loop == true
              retry_loop = false
              @pre_edit = deep_copy(@entities)
              new_list = run_editor

              # Perform validation on the input to ensure the user hasn't
              # changed the order of the objects or added/removed objects.
              @invalids = {}
              ask_defaults = {}
              new_list.each do |obj|
                old_obj = @entities[get_type(obj.class)][obj.name]
                unless compare_objs(obj, old_obj) == true
                  print "Error: Corrupted object list.  Press <Enter> to re-edit the objects from scratch"
                  gets
                  retry_loop = true
                  break
                end

#              # Entities that may need to sync
#              if obj.instance_of?(Mrg::Grid::SerializedConfigs::Node)
#                nsl.has_key?(:Node) ? nsl[:Node].merge!({obj.name=>obj}) : nsl[:Node] = {obj.name=>obj}
#                osl.has_key?(:Node) ? osl[:Node].merge!({old_obj.name=>old_obj}) : osl[:Node] = {old_obj.name=>old_obj}
#              elsif obj.instance_of?(Mrg::Grid::SerializedConfigs::GroupMembership)
#                nsl.has_key?(:Group) ? nsl[:Group].merge!({obj.name=>obj}) : nsl[:Group] = {obj.name=>obj}
#                osl.has_key?(:Group) ? osl[:Group].merge!({old_obj.name=>old_obj}) : osl[:Group] = {old_obj.name=>old_obj}
#              end
#
                # Verify all metadata is valid
                new_invalids = verify_obj(obj)
                new_invalids.keys.each {|k| @invalids.has_key?(k) ? @invalids[k] = @invalids[k].push(new_invalids[k]).flatten.uniq : @invalids[k] = new_invalids[k]}

                # Find params that might want default values
                if obj.instance_of?(Mrg::Grid::SerializedConfigs::Feature)
                  obj.params.keys.each {|k| (ask_defaults.has_key?(obj) ? ask_defaults[obj] = ask_defaults[obj].push(k).flatten.uniq : ask_defaults[obj] = [k]) if obj.params[k].empty?}
                end

                @entities[get_type(obj.class)][obj.name] = obj
              end

              if not @invalids.empty?
                puts "The store does not know about the following items:"
                @invalids.keys.each do |k|
                  puts "#{k}: #{@invalids[k].join(" ")}"
                end
                print "Should the above be added to the store [Y/n]? "
                answer = gets.strip
                if answer.downcase == "n"
                  # Remove all invalid parameters that might ask for default values
                  ask_defaults.each_key{|k| ask_defaults[k] -= @invalids[:Parameter]} if @invalids.has_key?(:Parameter)
  
                  # Remove all invalid entries for all objects
                  @entities.each_key{|k| @entities[k].each_value{|o| remove_invalid_entries(o)}}
                else
                  retry_loop = true
  
                  @invalids.each_pair do |key, value|
                    c = Mrg::Grid::Config::Shell.constants.grep(/Add#{key.to_s[0,4].capitalize}[a-z]*$/).to_s
                    value.each do |n|
                      @entities[key][n] = self.send("create_#{key.to_s.downcase}_obj", n)
                      @cmds.push([Mrg::Grid::Config::Shell.const_get(c), [n]])
                    end
                  end

                  # Synchronize any new group/node memberships
                  sync_memberships
                end
              end
            end

            if not ask_defaults.empty?
              ask_defaults.each_key do |obj|
                ask_defaults[obj].each do |p|
                  print "Use the default value for parameter '#{p}' in feature '#{obj.name}'? [Y/n] "
                  answer = gets.strip
                  obj.params[p] = 0 if answer.downcase != "n"
                end
              end
            end

            # Synchronize any new group/node memberships
            sync_memberships
          end
        end

#          def act
#            action = self.class.opname.split("-")[1].to_sym
#            cmds = []
#            @data.each_key do |type|
#              if action == :list
#              elsif action == :listall
#              elsif action == :delete
#              else
#                @data[type].each_key do |name|
#                  if action == :add
#                    c = Mrg::Grid::Config::Shell.constants.grep(/Add#{type.to_s[0,4].capitalize}[a-z]*$/).to_s
#                    cmds.push([Mrg::Grid::Config::Shell.const_get(c), @entities[type].keys.join(" ")])
#                  end
#                  cmds.push(self.send("update_#{type.to_s.downcase}_cmds", name, @data[type][name]))
#                end
#              end
#            end
#            puts cmds.inspect
#            return 0
#          end
#        end

        class CCSAdd < ::Mrg::Grid::Config::Shell::Command
          include CommonOps
          include CCSOps

          def self.opname
            "ccs-add"
          end
        
          def self.description
            "Add entities to the store"
          end

          def act
            @entities.each_key do |t|
              c = Mrg::Grid::Config::Shell.constants.grep(/Add#{t.to_s[0,4].capitalize}[a-z]*$/).to_s
              @entities[t].each_key do |n|
                @entities[t][n] = self.send("create_#{t.to_s.downcase}_obj", n)
                @cmds.push([Mrg::Grid::Config::Shell.const_get(c), [n]])
              end
            end
            @ogroups = @entities.has_key?(:Group) ? deep_copy(@entities[:Group]) : {}

            edit_objs

            @entities.each_key do |t|
              @entities[t].each_key do |n|
                @cmds.push(self.send("update_#{t.to_s.downcase}_cmds", n, @entities[t][n]))
              end
            end

            run_wscmds
            return 0
          end
        end

        class CCSEdit < ::Mrg::Grid::Config::Shell::Command
          include CommonOps
          include CCSOps

          def self.opname
            "ccs-edit"
          end
        
          def self.description
            "Edit entities in the store"
          end

          def act
            @entities.each_key do |t|
              m = Mrg::Grid::MethodUtils.find_store_method("get#{t.to_s.slice(0,4)}")
              @entities[t].each_key {|n| @entities[t][n] = self.send("create_#{t.to_s.downcase}_obj", n, store.send(m, n)) }
              
            end
            @ogroups = @entities.has_key?(:Group) ? deep_copy(@entities[:Group]) : {}

            edit_objs

            @entities.each_key do |t|
              @entities[t].each_key {|n| @cmds.push(self.send("update_#{t.to_s.downcase}_cmds", n, @entities[t][n])).compact!}
            end

            run_wscmds
            return 0
          end
        end

        class CCSList < ::Mrg::Grid::Config::Shell::Command
          include CommonOps
          include CCSOps

          def self.opname
            "ccs-list"
          end
        
          def self.description
            "List detailed information about entities in the store"
          end

          def act
            @entities.each_key do |type|
              c = Mrg::Grid::Config::Shell.constants.grep(/Show#{type.to_s[0,4].capitalize}[a-z]*$/).to_s
              @cmds.push([Mrg::Grid::Config::Shell.const_get(c), @entities[type].keys])
            end

            run_wscmds
            return 0
          end
          Mrg::Grid::Config::Shell.register_command(self, "ccp-list")
        end

        class CCSListAll < ::Mrg::Grid::Config::Shell::Command
          include CommonOps
          include CCSOps

          def self.opname
            "ccs-listall"
          end
        
          def self.description
            "List all names of entity types in the store"
          end

          def act
            @entities.each_key do |type|
              c = Mrg::Grid::Config::Shell.constants.grep(/List#{type.to_s[0,4].capitalize}[a-z]*$/).to_s
              @cmds.push([Mrg::Grid::Config::Shell.const_get(c), []])
            end

            run_wscmds
            return 0
          end

          Mrg::Grid::Config::Shell.register_command(self, "ccp-listall")
        end

        class CCSDelete < ::Mrg::Grid::Config::Shell::Command
          include CommonOps
          include CCSOps

          def self.opname
            "ccs-delete"
          end
        
          def self.description
            "Delete entities from the store"
          end

          def act
            puts "Warning: About to delete the following entities from the store:"
            @entities.each_key do |type|
              c = Mrg::Grid::Config::Shell.constants.grep(/Remove#{type.to_s[0,4].capitalize}[a-z]*$/).to_s
              @cmds.push([Mrg::Grid::Config::Shell.const_get(c), @entities[type].keys])
              puts "#{type}: #{@entities[type].keys.join(", ")}"
            end
            print "Proceed to delete the above entities from the store [y/N]? "
            answer = gets.strip
            if answer.downcase != "y"
              return 0
            end

            run_wscmds
            return 0
          end
        end

        class CCPAdd < ::Mrg::Grid::Config::Shell::Command
          include CommonOps
          include CCPOps
          include UXOps

          def self.opname
            "ccp-add"
          end
        
          def self.description
            "Append to the group/node with lowest priority"
          end
        end

        class CCPRemove < ::Mrg::Grid::Config::Shell::Command
          include CommonOps
          include CCPOps
          include UXOps

          def self.opname
            "ccp-remove"
          end
        
          def self.description
            "Remove from the group/node"
          end
        end

        class CCPInsert < ::Mrg::Grid::Config::Shell::Command
          include CommonOps
          include CCPOps
          include UXOps

          def self.opname
            "ccp-insert"
          end
        
          def self.description
            "Insert into the group/node with highest priority"
          end

          def finalize_params
puts "add_params = #{add_params.inspect}"
            add_params.replace(target_obj.params.merge(add_params))
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

        class CCPEdit < ::Mrg::Grid::Config::Shell::Command
          include CommonOps
          include CCPOps
          include UXOps

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
            group = Mrg::Grid::SerializedConfigs::Group.new
#            group.saved_fields.delete(:is_identity_group)
            group.name = @target.values.to_s
            group.features = target_obj.features
            group.params = target_obj.params
            group
          end

          def serialize
            @serialized ||= group_obj
          end

          def min_args
            1
          end

          def finalize_params
            edit_params.merge!(add_params)
          end

          def add_params
            @padded ||= {}
          end

          def remove_params
            @premoved ||= {}
          end

          def add_features
            @fadded ||= []
          end

          def remove_features
            @fremoved ||= []
          end

          def edit_params
            @entities[:edit][:Parameter] ||= {}
          end

          def edit_features
            @entities[:edit][:Feature] ||= []
          end

          def edit_target
            warnings = [[:Feature, "list of features"],
                        [:Parameter, "list of parameters"],
                        [:schedds, "request to prompt for schedd information"],
                        [:qmf, "request to prompt for broker information"]
                       ]
            warnings.each do |key, txt|
              puts "Warning: Ignoring #{txt} in edit mode" if @options.has_key?(key) || @entities[action].has_key?(key)
              @options.delete(key) if @options.has_key?(key)
              @entities[action].delete(key) if @entities[action].has_key?(key)
            end

            edited = run_editor
puts edited.inspect
puts "entities after edit: #{@entities.inspect}"
            add_params.replace(Hash[edited.params.select{|k, v| (not target_obj.params.keys.include?(k)) || ([k, v] != [k, target_obj.params[k]])}])
            remove_params.replace(Hash[target_obj.params.select{|k, v| (not edited.params.keys.include?(k))}])
            add_features.replace(edited.features.select{|n| (not target_obj.features.include?(n))})
            remove_features.replace(target_obj.features.select{|n| (not edited.features.include?(n))})
puts "add params: #{add_params.inspect}"
puts "remove params: #{remove_params.inspect}"
puts "add features: #{add_features.inspect}"
puts "remove features: #{remove_features.inspect}"
            edit_params.replace(edited.params)
            edit_features.replace(edited.features)
puts "edit params: #{edit_params.inspect}"
puts "edit features: #{edit_features.inspect}"
          end
        end
      end
    end
  end
end
