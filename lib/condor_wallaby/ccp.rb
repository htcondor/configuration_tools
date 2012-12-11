# CCP: condor_configure_pool argument parsing and pass off to wallaby shell
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
      class CCP
        include CmdLineUtils 
        def store_types
          [:Feature, :Group, :Node, :Parameter, :Snapshot]
        end

        def entities
          [:Feature, :Parameter]
        end

        def main(args)
          ws_args = []
          options = {}

          mechs = Mrg::Grid::Config::Shell::VALID_MECHANISMS

          @op = OptionParser.new do |opts|
            opts.banner = "Usage: #{File.basename($0)} [options] <action> <target> [config entities]"

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
              ws_args += ["-p", p.to_s]
            end

            opts.on("-U", "--user NAME", "The username used to authenticate with the qpid broker") do |n|
              ws_args += ["-U", n]
            end

            opts.on("-P", "--password PASS", "The password used to authenticate with the qpid broker") do |p|
              ws_args += ["-P", p]
            end

            opts.on("-m", "--auth-mechanism PASS", mechs, "Authentication mechanism (#{mechs.join(", ")}) for authenticating with the qpid broker") do |m|
              ws_args += ["-M", m]
            end

            opts.on("--schedds", "Prompt for scheduler information") do
              options[:schedds] = true
            end

            opts.on("--qmfbroker", "Prompt for QMF broker information") do
              options[:qmf] = true
            end

            opts.on("-v", "--verbose", "Print more information, if available") do
              options[:verbose] = true
            end

            opts.separator ""
            opts.separator "Target: (Only 1 allowed per invocation)"

            targets = [["", "default-group", "Perform actions on the Internal Default Group in the store", nil],
                       ["n", "node", "The name of a specific machine that will have the configuration changes applied to it", "NAME"],
                       ["g", "group", "The name of the group that will have the configuration changes applied to it", "NAME"],
                       ["", "skel-group", "Perform actions on the Skeleton Group in the store", nil]]
            targets.each do |short, long, desc, arg|
              s = "-#{short}" unless short.empty?
              opts.on(s, "--#{[long, arg].join(" ")}", desc) do |n|
                if options.has_key?(:target)
                  puts "Can only configure 1 node or group at a time"
                  exit(1)
                end
                t = long.split('-')
                options[:target] = t[0].capitalize.to_sym if t.length < 2
                options[:target] = t[1].capitalize.to_sym if t.length > 1
                options[:target_name] = n if n
                options[:target_name] = "+++DEFAULT" if n && n.downcase.include?("internal default group")
                options[:target_name] = "+++#{long.split("-").first.upcase}" unless n
              end
            end

            opts.separator ""
            opts.separator "Action: (Only 1 allowed per invocation)"

            actions = [[:add, "Append to the group/node with lowest priority"],
                       [:delete, "Remove from the group/node"],
                       [:edit, "Edit the group/node"],
                       [:insert, "Insert into the group/node with highest priority"],
                       [:list, "List detailed information"],
                       [:activate, "Attempt to activate the configuration in the store"]]
            actions.each do |name, desc|
              short = "-#{name.to_s[0,1]}" unless name == :activate
              opts.on(short, "--#{name}", desc) do
                if options.has_key?(:action)
                  puts "Only 1 action may be specified"
                  exit(1)
                end
                options[:action] = name
                options[:action] = :remove if name == :delete
              end
            end

            ["load", "take", "remove"].each do |type|
              opts.on("--#{type}-snapshot NAME", "#{type.capitalize} snapshot with the given name") do |n|
                if options.has_key?(:action)
                  puts "Only 1 action may be specified"
                  exit(1)
                end
                options[:action] = :snapshot
                options[:snapshot] = {:type=>type.gsub(/t/, "m").to_sym, :name=>n}
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
            opts.separator "Config Entities:"

            entities.each do |n|
              ln = n.to_s.slice(0,5).upcase
              ln.chop! if n == :Feature
              on = n.to_s.downcase + "s"
              on = ln.downcase + "s" if n == :Parameter
              opts.on("-#{n.to_s[0,1].downcase}", "--#{on} #{ln}[,#{ln},...]", "A comma separated list of #{n}s") do |list|
                if options.has_key?(n)
                  options[n] += "," + list
                else
                  options[n] = list
                end
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
          opts.push("--schedds") if options.has_key?(:schedds)
          opts.push("--qmf") if options.has_key?(:qmf)
          opts.push("--verbose") if options.has_key?(:verbose)
  
          # Generate the option string to pass to the shell command
          opts.push("#{options[:target]}=#{options[:target_name]}") if options.has_key?(:target)
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

          cmd = "ccp-#{options[:action]}"
          if options[:action] == :snapshot
            cmd = "#{options[:snapshot][:type]}-#{options[:action]}"
            opts = [options[:snapshot][:name]]
          end
          if options[:action] == :activate
            cmd = "#{options[:action]}"
            opts = []
          end

          # Call wallaby shell ccp to perform the actions
          Mrg::Grid::Config::Shell::install_commands()
          Mrg::Grid::Config::Shell::main(ws_args + [cmd] + opts.flatten)
        end
      end
    end
  end
end
