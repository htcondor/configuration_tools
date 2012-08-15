# cmdline: command line parsing utilities
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

module Mrg
  module Grid
    module Config
      module CmdLineUtils
        def parse_option_args(args)
          items = []
          quotes = false
          current = ""
          args.each_byte do |c|
            c = c.chr
            if (c == '"') || (c == "'"):
              if quotes == false
                quotes = true
                next
              else
                quotes = false
                next
              end
            elsif (c == ',') && (quotes == false)
              items.push(current)
              current = ""
              next
            end
            current << c
          end
          items.push(current) if current and (not current.empty?)
          items
        end
      end
    end
  end
end
