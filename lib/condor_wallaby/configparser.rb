# configparser.rb: Config file parser
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
# # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'tempfile'

module Wallaroo
  module Shell
    class ConfigParser
      def self.parse(text)
        data = Hash.new {|h,k| h[k] = {}}
        section = ""
        text.split(/\n/).each do |line|
          nvp = nil
          if line =~ /\s*\[(.+)\]/
            section = $1 
            next
          end
          if section.empty? || line.strip.empty? || line =~ /\s*#/
            next
          end
          nvp = line.split('=', 2) if line.include?('=')
          nvp = line.split(':', 2) if line.include?(':') if not nvp
          data[section][nvp[0].strip.to_sym] = nvp[1].strip if nvp
        end
        data
      end
    end
  end
end

