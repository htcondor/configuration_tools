# commandoptions.rb: Command line options for condor wallaby shell commands
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

module Wallaroo
  module Shell
    module CommandOptions
      def init_option_parser
        OptionParser.new do |opts|
          opts.banner = "Usage:  wallaby #{self.class.opname} [OPTIONS] NAME ARG=VALUE ...\n#{self.class.description}"

          opts.on("-h", "--help", "displays this message") do
            puts @oparser
            exit
          end

          opts.on("-f", "--file INFILE", "read feature data from INFILE.") do |f|
            @options[:infile] = f
          end

          opts.on("-i", "--include INCLUDE", "name of the feature to include (default VMUniverse)") do |inc|
            config[:include] = inc
          end

          opts.on("-s", "--save", "save configuration to a file.  The file will be named after the #{noun} name") do
            @options[:save] = true
          end

          extra_options(opts)
        end
      end

      def extra_options(o)
        nil
      end
    end
  end
end
