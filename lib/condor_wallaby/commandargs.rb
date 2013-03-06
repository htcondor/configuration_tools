# commandargs.rb: Define arguments for use by condor wallaby shell commands
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
    module CommandArgs
      def self.included(receiver)
        if receiver.respond_to?(:cmd_args)
          define_method :arg_list do
            @a ||= receiver.cmd_args
          end

          receiver.cmd_args.each do |arg|
            define_method arg.gsub(/-/, '_').to_sym do 
              a = arg.gsub(/-/, '_').to_sym
              config[a] || fdata(a) || get_env("#{env_prefix}_#{arg.gsub(/-/, '_').upcase}") || base[a] || nil
            end
          end
        end

        if receiver.respond_to?(:register_callback)
          receiver.register_callback :initializer, :init
          receiver.register_callback :after_option_parsing, :parse_args
        end
      end

      def init
        @fdata = Hash.new {|h,k| h[k] = {}}
        @options = {}
      end

      def get_env(n)
        return ENV[n].to_sym if ENV.keys.include?(n)
        nil
      end

      def fdata(arg)
        @fdata.keys.include?(name) ? @fdata[name][arg] : nil
      end

      def config
        @config ||= {}
      end

      def base
        @basefeature ||= {}
      end

      def env_prefix
        nil
      end

      def name
        config[:name] || ENV["#{env_prefix}_NAME"] || nil
      end

      def include
        config[:include] || fdata(:include) || def_include
      end

      def read_file
        if @options.has_key?(:infile)
          exit!(1, "#{@options[:infile]} no such file") if not File.exist?(@options[:infile])
          @fdata.merge!(ConfigParser.parse(File.read(@options[:infile])))
        end
      end

      def parse_args(*args)
        if @options.has_key?(:base)
          route = store.getFeature(prefix+@options[:base]).parameters["JOB_ROUTER_ENTRIES"]
          route.split(';').each do |line|
            nvp = line.split('=', 2)
            arg_list.each do |c|
              if nvp[0].include?(c)
                base[c.gsub(/-/, '_').to_sym] = nvp[1].strip.tr('"', '')
              end
            end
          end
        end

        exit!(1, "you must specify a name for the #{noun}") if args.size < 1 && (not name) && (not @options.has_key?(:infile))
        config[:name] = args.shift if args.count > 0 && (not name) && (not @options.has_key?(:infile))
        args.each do |arg|
          nvp = arg.split('=', 2)
          exit!(1, "#{nvp[0]} is not a valid option") if not arg_list.include?(nvp[0].downcase)
          config[nvp[0].gsub(/-/, '_').downcase.to_sym] = nvp[1].downcase
        end
        read_file
      end
    end
  end
end
