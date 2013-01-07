# utils: utilities for running commands
#
# Copyright (c) 2012 Red Hat, Inc.
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
    module Config
      module Shell
        module ToolUtils

          def run_wscmds(cmd_list)
            ret = 0
            cmd_list.compact.each do |cmdset|
              cret = cmdset[0].new(store, "").main(cmdset[1].flatten)
              puts "warning: #{cmdset[0].to_s.split("::").last} returned non-zero" if cret != 0
              ret |= cret
            end
            ret
          end

          def run_cmdline(cmd)
            pid = Process.fork()
            if pid == nil
              exec(cmd)
            else
              Process.waitpid(pid, 0)
            end
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

          def params_as_array(phash)
            list = []
            phash.each_pair do |k, v|
              list.push("#{k}=#{v}") if v
              list.push(k) if not v
            end
            list
          end

          def self.remove_fields
            [:idgroup, :last_updated_version, :provisioned, :is_identity_group]
          end

          def action
            self.class.opname.split("-")[1].to_sym
          end

          def cmd_prefix
            self.class.opname.split("-")[0].to_sym
          end

          def serialize
            list = []
            @entities.each_key do |type|
              list.push(@entities[type].values).flatten!
            end
            list
          end

          def deep_copy(obj)
            YAML::parse(obj.to_yaml).transform
          end

          def compare_objs(obj1, obj2)
            # These field types can't be changed.  All others end up as strings
            static_types = [Hash, Array]
            fields = []

            same_field_types = true

            obj1.instance_variables.each {|f| fields += [f] if static_types.include?(obj1.instance_variable_get(f).class)}
            obj2.instance_variables.each {|f| fields += [f] if static_types.include?(obj2.instance_variable_get(f).class) && (not fields.include?(f))}
            fields.each {|f| (same_field_types = obj1.instance_variable_get(f).class == obj2.instance_variable_get(f).class && same_field_types)}
            (obj1.class == obj2.class) && (obj1.name == obj2.name) && same_field_types
          end
        end

        module QmfConversion
          def self.find_getter(attr, klass)
            a = attr.split('_')
            m = nil
            begin
              m = Mrg::Grid::MethodUtils.find_property(a[0], klass)[0].to_sym
            rescue
              if a.length > 1
                m = Mrg::Grid::MethodUtils.find_property(a[1], klass)[0].to_sym
              end
            end
            m = Mrg::Grid::MethodUtils.find_method(a[0], klass)[0].to_sym if m == nil
            m
          end
        end
      end
    end
  end
end
