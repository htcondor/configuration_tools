# CCS: condor_configure_store argument parsing and pass off to wallaby shell
# Copyright 2012 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
require 'optparse'
require 'mrg/grid/config/shell'
require 'condor_wallaby/cmdline'

module Mrg
  module Grid
    module Config
      class CCS
        include CmdLineUtils

        def store_types
          [:Feature, :Group, :Node, :Parameter, :Subsystem]
        end

        def main(args)
          ws_args = []
          verbose = false
          options = {}

          mechs = Mrg::Grid::Config::Shell::VALID_MECHANISMS

          @op = OptionParser.new do |opts|
            opts.banner = "Usage: #{File.basename($0)} [options] <action> <target(s)>"

            opts.separator ""
            opts.separator "Options:"
            opts.on("-h", "--help", "shows this message") do
              puts @op
              exit(0)
            end

            opts.on("-b", "--broker HOSTNAME", "The qpid broker hostname used by the configuration store") do |h|
              ws_args += ["-H", h]
            end

            opts.on("-o", "--port NUM", Integer, "The qpid broker port used by the configuration store") do |p|
              ws_args += ["-p", p]
            end

            opts.on("-U", "--user NAME", "The username used to authenticate with the qpid broker") do |n|
              ws_args += ["-U", n]
            end

            opts.on("-P", "--password PASS", "The password used to authenticate with the qpid broker") do |p|
              ws_args += ["-P", p]
            end

            opts.on("-m", "--auth-mechanism PASS", mechs, "Authentication mechanisms (#{mechs.join(", ")}) for authenticating with the qpid broker") do |m|
              ws_args += ["-M", m]
            end

            opts.on("-v", "--verbose", "Print more information, if available") do
              options[:verbose] = true
            end

            opts.separator ""
            opts.separator "Action: (Only 1 allowed per invocation)"

            actions = [["a", "add", "Add the target(s) to the store"],
                       ["d", "delete", "Remove the target(s) from the store"],
                       ["e", "edit", "Edit the target(s) in the store"],
                       ["l", "list", "List specific information about the target(s) provided"]]
            actions.each do |short, long, desc|
              opts.on("-#{short}", "--#{long}", desc) do
                if options.has_key?(:action)
                  puts "Only 1 action may be specified"
                  exit(1)
                end
                options[:action] = long.to_sym
              end
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
                if options.has_key?(:action) && options[:action] != :listall
                  puts "Actions and List Actions cannot be combined"
                  exit(1)
                end
                options[type] = ""
                options[:action] = :listall
              end
            end

            opts.separator ""
            opts.separator "Targets:"

            store_types.each do |type|
              str = type.to_s.downcase
              nl = str.slice(0,5).upcase
              type == :Parameter || type == :Subsystem ?  on = nl.downcase + "s": on = str + "s"
              nl.chop!  if type == :Feature
              nl += "S"  if type == :Subsystem
              opts.on("-#{on[0,1]}", "--#{on} #{nl}[,#{nl},...]", "A comma separated list of #{str}s") do |list|
                options[type] = list
              end
            end
          end

          begin
            @op.parse!(args)
          rescue OptionParser::InvalidOption => io
            puts io
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
          rescue OptionParser::MissingArgument => ma
            puts ma
            puts @op
            exit(1)
          end

          unless options.has_key?(:action)
            puts "No action specified.  Exiting"
            puts @op
            exit(1)
          end

          opts = []
          opts.push("--verbose") if options.has_key?(:verbose)
          options.each_key do |type|
            next if not store_types.include?(type)
            if options[type].empty?
              opts.push(type.to_s)
            else
              parse_option_args(options[type]).each do |name|
                opts.push("#{type}=#{name}")
              end
            end
          end
  
          # Call wallaby shell ccs to perform the actions
          Mrg::Grid::Config::Shell::install_commands()
          Mrg::Grid::Config::Shell::main(ws_args + ["ccs-#{options[:action]}"] + opts.flatten)
        end
      end
    end
  end
end
