#!/usr/bin/ruby
#   Copyright 2008 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
require 'optparse'
require 'mrg/grid/config/shell'

module Mrg
  module Grid
    module Config
      class CCS
        def store_types
          [:Node, :Parameter, :Feature, :Group, :Subsystem]
        end

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
          items.push(current)
          items
        end

        def main(args)
          ws_args = []
          verbose = false
          options = {}
          host = "localhost"
          port = 5672
          username = nil
          password = nil
          auth_mechanisms = nil
          settings = Qmf::ConnectionSettings.new

          @op = OptionParser.new do |opts|
            opts.banner = "Usage: #{File.basename($0)} [options] <action> <target(s)>"

            opts.separator ""
            opts.separator "Options:"
            opts.on("-h", "--help", "shows this message") do
              puts @op
              exit(0)
            end

            opts.on("-b", "--broker HOSTNAME", "The qpid broker hostname used by the configuration store") do |h|
              ws_args << ["-H", h]
              host = h
            end

            opts.on("-o", "--port NUM", Integer, "The qpid broker port used by the configuration store") do |p|
              ws_args << ["-p", p]
              port = p
            end

            opts.on("-U", "--user NAME", "The username used to authenticate with the qpid broker") do |n|
              ws_args << ["-U", n]
              username = n
            end

            opts.on("-P", "--password PASS", "The password used to authenticate with the qpid broker") do |p|
              ws_args << ["-P", p]
              password = p
            end

            opts.on("-M", "--auth-mechanism PASS", %w{ANONYMOUS PLAIN GSSAPI}, "A comma separated list of authentication mechanisms (#{%w{ANONYMOUS PLAIN GSSAPI}.join(", ")}) for authenticating with the qpid broker") do |m|
              ws_args << ["-M", m]
              auth_mechanisms = m
            end

            opts.on("-v", "--verbose", "Print more information, if available") do
              verbose = true
            end

            opts.separator ""
            opts.separator "Action: (Only 1 allowed per invocation)"

            opts.on("-a", "--add", "Add the target(s) to the store") do
              if options.has_key?(:action)
                puts "Only 1 action may be specified"
                exit(1)
              end
              options[:action] = :add
            end

            opts.on("-d", "--delete", "Remove the target(s) from the store") do
              if options.has_key?(:action)
                puts "Only 1 action may be specified"
                exit(1)
              end
              options[:action] = :delete
            end

            opts.on("-e", "--edit", "Edit the target(s) in the store") do
              if options.has_key?(:action)
                puts "Only 1 action may be specified"
                exit(1)
              end
              options[:action] = :edit
            end

            opts.on("-l", "--list", "List specific information about the target(s) provided") do
              if options.has_key?(:action)
                puts "Only 1 action may be specified"
                exit(1)
              end
              options[:action] = :list
            end

            opts.separator ""
            opts.separator "List Action: (Cannot be combined with actions)"
            store_types.each do |type|
              if type == :Parameter
                str = "param"
              else
                str = type.to_s.downcase
              end
              opts.on("--list-all-#{str}s", "List all #{str}s in the store") do
                if options.has_key?(:action) and options[:action] != :listall
                  puts "Actions and List Actions cannot be combined"
                  exit(1)
                end
                options[str.capitalize.to_sym] = ""
                options[:action] = :listall
              end
            end

            opts.separator ""
            opts.separator "Targets:"

            store_types.each do |type|
              str = type.to_s.downcase
              nl = str.slice(0,5).upcase
              nl = str.slice(0,6).upcase if type == :Subsystem
              if type == :Subsystem
                on = nl.downcase
              elsif type == :Parameter
                on = nl.downcase + "s"
              elsif nl.length == 6
                on = str.chop + "s"
              else
                on = str + "s"
              end
              if type == :Feature
                nl.chop!
              end
              opts.on("-#{on[0,1]}", "--#{on} #{nl}[,#{nl},...]", "A comma separated list of #{str}s") do |list|
                options[type] = list
              end
            end
          end

          begin
            @op.parse!(args)
          rescue OptionParser::InvalidOption
            puts @op
            exit(1)
          rescue OptionParser::InvalidArgument => ia
            puts ia
            puts @op
            exit(1)
          rescue OptionParser::AmbiguousOption => ao
            puts ao
            puts @op
            exit(1)
          end

          if not options.has_key?(:action)
            puts "No action specified.  Exiting"
            puts @op
            exit(1)
          end

          continue = false
          store_types.each do |t|
            continue = continue || options.has_key?(t)
          end
          if not continue
            puts "No targets or list actions specified.  Exiting"
            puts @op
            exit(1)
          end

          opts = []
          options.each_key do |type|
            if (type == :action)
              next
            end
            parse_option_args(options[type]).each do |name|
              opts.push("#{type}=#{name}")
            end
          end
  
          # Call wallaby shell ccs to perform the actions
          ENV['WALLABY_COMMAND_DIR'] = "./commands"
          Mrg::Grid::Config::Shell::install_commands()
          Mrg::Grid::Config::Shell::main(ws_args + ["ccs-#{options[:action]}"] + opts.flatten)
        end
      end
    end
  end
end


Mrg::Grid::Config::CCS.new.main(ARGV)
