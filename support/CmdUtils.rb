# CmdUtils: run commands in a shell
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
require 'condor_wallaby_tools/OpUtils'

module Mrg
  module Grid
    module Config
      module Shell
        module CmdUtils
          include OpUtils

          def run_wscmds(cmd_list)
            cmd_list.compact!
            cmd_list.each do |cmdset|
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
      end
    end
  end
end
