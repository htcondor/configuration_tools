# cmd_ccs.rb: edit entities in wallaby
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

module Mrg
  module Grid
    module Config
      module Shell
        module CCSOps
          include ToolUtils

          def self.remove_fields(klass)
            f = ToolUtils.remove_fields
            f += [:params, :features] if klass == "Group"
            f
          end

          def add_group_fields
            {:members=>Set}
          end

          def ws_bool(value)
            value ? "yes" : "no"
          end

          def init_option_parser
            @options = {}
            OptionParser.new do |opts|
              opts.banner = "Usage:  wallaby #{self.class.opname} FILENAME [COMPARE_FILENAME]\n#{self.class.description}"
        
              opts.on("-h", "--help", "displays this message") do
                puts @oparser
                exit
              end

              opts.on("-v", "--verbose", "Print more information, if available") do
                @options[:verbose] = true
              end
            end
          end

          def min_args
            1
          end

          def parse_args(*args)
            @cmds = []
            if args.size < min_args
              exit!(1, "no targets specified")
            end

            @entities = Hash.new {|h,k| h[k] = Hash.new {|h1,k1| h1[k1] = {}}}
            args.each do |arg|
              as = arg.split('=', 2)
              @entities[as[0].to_sym][as[1]] = nil
            end

            exit!(1, "can not #{action} the group +++DEFAULT") if @entities.has_key?(:Group) && @entities[:Group].has_key?("+++DEFAULT")
          end

          def self.included(receiver)
            if receiver.respond_to?(:register_callback)
              receiver.register_callback :after_option_parsing, :parse_args
            end
          end
        
          def create_obj(name, sctype, qmf_obj=nil)
            type = sctype.to_s
            klass = Mrg::Grid::SerializedConfigs.const_get(type)
            CCSOps.remove_fields(type).each do |f|
              klass.saved_fields.delete(f)
            end
            if self.respond_to?("add_#{type.downcase}_fields")
              self.send("add_#{type.downcase}_fields").each_pair do |n, t|
                klass.field n, t
              end
            end

            obj = klass.new
            obj.name = name

            # The list of getters without fields disallowed to be 
            # displayed/modified
            attrs = obj.instance_variables.collect{|n| n.delete("@")}

            if qmf_obj != nil
              attrs.each do |m|
#                sp = m.split('_')
#                qmf_m = nil
#                klass = type.gsub(/Membership/, '')
#                begin
#                  qmf_m = Mrg::Grid::MethodUtils.find_property(sp[0], klass)[0].to_sym
#                rescue
#                  if sp.count > 1
#                    qmf_m = Mrg::Grid::MethodUtils.find_property(sp[1], klass)[0].to_sym
#                  end
#                end
#                qmf_m = Mrg::Grid::MethodUtils.find_method(sp[0], klass)[0].to_sym if qmf_m == nil
#puts m.inspect
                obj.send("#{m}=", qmf_obj.send(Mrg::Grid::Config::Shell::QmfConversion.find_getter(m, type.gsub(/Membership/, ''))))
              end
            else
              # sanitize by converting sets into arrays
              attrs.each do |m|
                if obj.send(m).instance_of?(Set)
                  obj.send("#{m}=", [])
                end
              end
            end
            obj
          end

          def update_node_cmds(name, obj)
            [[Mrg::Grid::Config::Shell.const_get("ReplaceNodeMembership"), [name] + obj.membership]]
          end

          def update_feature_cmds(name, obj)
            cmds = [[Mrg::Grid::Config::Shell.const_get("ReplaceFeatureParam"), [name] + params_as_array(obj.params)]]
            cmds << [Mrg::Grid::Config::Shell.const_get("ReplaceFeatureInclude"), [name] + obj.included]
            cmds << [Mrg::Grid::Config::Shell.const_get("ReplaceFeatureConflict"), [name] + obj.conflicts]
            cmds << [Mrg::Grid::Config::Shell.const_get("ReplaceFeatureDepend"), [name] + obj.depends]
            cmds
          end

          def update_parameter_cmds(name, obj)
            args = []
            args += ["--kind", "#{obj.kind}"] if not obj.kind.empty?
            args += ["--default-val", "#{obj.default_val}"] if not obj.default_val.empty?
            args += ["--description", "#{obj.description}"] if not obj.description.empty?
            args += ["--must-change", "#{ws_bool(obj.must_change)}"]
            args += ["--level", "#{obj.level}"]
            args += ["--needs-restart", "#{ws_bool(obj.needs_restart)}"]
            cmds = [[Mrg::Grid::Config::Shell.const_get("ModifyParam"), [name] + args]]
            cmds << [Mrg::Grid::Config::Shell.const_get("ReplaceParamConflict"), [name] + obj.conflicts]
            cmds << [Mrg::Grid::Config::Shell.const_get("ReplaceParamDepend"), [name] + obj.depends]
            cmds
          end

          def update_subsystem_cmds(name, obj)
            [[Mrg::Grid::Config::Shell.const_get("ReplaceSubsysParam"), [name] + obj.params]]
          end

          def update_group_cmds(name, obj)
            cmds = []
            obj.members.each do |node|
              if @orig_grps.has_key?(name) && (not @orig_grps[name].members.include?(node))
                # Node was added
                cmds << [Mrg::Grid::Config::Shell::AddNodeMembership, [node, name]]
              end
            end
            if @orig_grps.has_key?(name)
              @orig_grps[name].members.each do |node|
                if not obj.members.include?(node)
                  # Node was removed
                  cmds << [Mrg::Grid::Config::Shell::RemoveNodeMembership, [node, name]]
                end
              end
            end
            cmds
          end

          def compare_objs(obj1, obj2)
            (obj1.class == obj2.class) && (obj1.name == obj2.name)
          end

          def remove_invalid_entries(obj)
            # Generate the list of entity names the obj uses
            if @invalids.has_key?(:Parameter)
              (obj.params.instance_of?(Hash) ? @invalids[:Parameter].each{|i| obj.params.delete(i)} : obj.params -= @invalids[:Parameter]) if obj.respond_to?(:params)
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
          end

          def verify_obj(obj)
            bad_names = {}
            names = {}

            # Generate the list of entity names the obj uses
            names[:Parameter] = obj.respond_to?(:params) && (obj.params != nil) ? (obj.params.instance_of?(Hash) ? obj.params.keys : obj.params) : []
            names[:Group] = obj.respond_to?(:membership) ? obj.membership : []
            names[:Node] = obj.respond_to?(:members) ? obj.members : []
            names[:Feature] = obj.respond_to?(:features) && (obj.features != nil) ? obj.features : []
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
              bad = []
              list = names[t]
              list -= @entities[t].keys if @entities.has_key?(t)
              bad = store.send("check#{t}Validity", list) if not list.empty?
              bad_names[t] = bad if not bad.empty?
            end

            bad_names
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
            return :Group if klass_name.to_s.split('::').last == "GroupMembership"
            klass_name.to_s.split('::').last.to_sym
          end

          def deep_copy(obj)
            YAML::parse(obj.to_yaml).transform
          end

          def edit_objs
            retry_loop = true
            @orig_grps = @entities.has_key?(:Group) ? deep_copy(@entities[:Group]) : {}

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
                  $stdin.gets
                  retry_loop = true
                  break
                end

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
                answer = $stdin.gets.strip
                if answer.downcase == "n"
                  # Remove all invalid parameters that might ask for default
                  # values
                  ask_defaults.each_key{|k| ask_defaults[k] -= @invalids[:Parameter]} if @invalids.has_key?(:Parameter)
  
                  # Remove all invalid entries for all objects
                  @entities.each_key{|k| @entities[k].each_value{|o| remove_invalid_entries(o)}}
                else
                  retry_loop = true
  
                  @invalids.each_pair do |key, value|
                    c = Mrg::Grid::Config::Shell.constants.grep(/Add#{key.to_s[0,4].capitalize}[a-z]*$/).to_s
                    value.each do |n|
                      @entities[key][n] = create_obj(n, key)
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
                  answer = $stdin.gets.strip
                  obj.params[p] = nil if answer.downcase != "n"
                end
              end
            end

            # Synchronize any new group/node memberships
            sync_memberships
          end

          def gen_update_cmds
            @entities.each_key do |t|
              @entities[t].each_pair do |n, o|
                @cmds += self.send("update_#{t.to_s.downcase}_cmds", n, o)
              end
            end
          end
        end

        class CCSAdd < ::Mrg::Grid::Config::Shell::Command
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
                @entities[t][n] = create_obj(n, t)
                @cmds.push([Mrg::Grid::Config::Shell.const_get(c), [n]])
              end
            end
#            @orig_grps = @entities.has_key?(:Group) ? deep_copy(@entities[:Group]) : {}

            edit_objs
            gen_update_cmds

#            @entities.each_key do |t|
#              @entities[t].each_key do |n|
#                @cmds += self.send("update_#{t.to_s.downcase}_cmds", n, @entities[t][n])
#              end
#            end

            run_wscmds(@cmds)
            return 0
          end
        end

        class CCSEdit < ::Mrg::Grid::Config::Shell::Command
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
              @entities[t].each_key {|n| @entities[t][n] = create_obj(n, t, store.send(m, n)) }
              
            end
#            @orig_grps = @entities.has_key?(:Group) ? deep_copy(@entities[:Group]) : {}

            edit_objs
            gen_update_cmds

#            @entities.each_key do |t|
#              @entities[t].each_key do |n|
#                @cmds += self.send("update_#{t.to_s.downcase}_cmds", n, @entities[t][n])
#              end
#            end

            run_wscmds(@cmds)
            return 0
          end
        end

        class CCSList < ::Mrg::Grid::Config::Shell::Command
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
              cmd = Mrg::Grid::Config::Shell.const_get(c)
              @entities[type].each_key do |name|
                @cmds.push([cmd, [name]])
                if type == :Node and @options.has_key?(:verbose)
                  @cmds.push([Mrg::Grid::Config::Shell::ShowNodeConfig, [name]])
                end
              end
            end

            run_wscmds(@cmds)
            return 0
          end
        end

        class CCSListAll < ::Mrg::Grid::Config::Shell::Command
          include CCSOps

          def self.opname
            "ccs-listall"
          end
        
          def self.description
            "List all names of entity types in the store"
          end

          def min_args
            0
          end

          def act
            @entities.each_key do |type|
              c = Mrg::Grid::Config::Shell.constants.grep(/List#{type.to_s[0,4].capitalize}[a-z]*$/).to_s
              @cmds.push([Mrg::Grid::Config::Shell.const_get(c), []])
            end

            run_wscmds(@cmds)
            return 0
          end

          Mrg::Grid::Config::Shell.register_command(self, "ccp-listall")
        end

        class CCSDelete < ::Mrg::Grid::Config::Shell::Command
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
            answer = $stdin.gets.strip
            if answer.downcase != "y"
              return 0
            end

            run_wscmds(@cmds)
            return 0
          end
        end
      end
    end
  end
end
