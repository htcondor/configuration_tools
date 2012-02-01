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
        module CCSOps
          def init_option_parser
            @delete = false
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

          def run_wscmds
            @cmds.compact!
            @cmds.each do |cmdset|
              puts "cmdset = #{cmdset.inspect}"
              puts "cmd = #{cmdset[0].inspect}"
              puts "args = #{cmdset[1].to_s.inspect}"
              cmdset[0].new(store, "").main(cmdset[1])
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
#              list -= @already_added[t] if @already_added.has_key?(t)
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
            editor = ENV['EDITOR'] || "/bin/vi"
#            @already_added = {}

            # Dump the data into a file and open an editor
            yaml_file = Tempfile.new("ccs")
            while retry_loop == true
              retry_loop = false
              @pre_edit = deep_copy(@entities)
              yaml_file.seek(0, IO::SEEK_SET)
              yaml_file.truncate(0)
              yaml_file.write(serialize.to_yaml)
              yaml_file.flush
              run_cmdline("#{editor} #{yaml_file.path}")
              yaml_file.flush
              yaml_file.seek(0, IO::SEEK_SET)
              new_list = YAML::parse(yaml_file.read).transform

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
#                      @already_added.has_key?(key) ? @already_added[key].push(n) : @already_added[key] = [n]
#                    nsl.has_key?(key) ? nsl[key].merge!({@entities[key][n].name=>@entities[key][n]}) : nsl[key] = {@entities[key][n].name=>@entities[key][n]}
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
        end

        class CCSListAll < ::Mrg::Grid::Config::Shell::Command
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
            answer = gets.strip
            if answer.downcase != "y"
              return 0
            end

            run_wscmds
            return 0
          end
        end
      end
    end
  end
end
