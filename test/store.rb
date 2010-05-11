#!/usr/bin/ruby

require 'spqr/spqr'
require 'spqr/app'
require 'rhubarb/rhubarb'

module Mrg
   module Grid
      module Config
         class Store
            include ::SPQR::Manageable
            qmf_package_name 'mrg.grid.config'
            qmf_class_name 'Store'

            def Store.find_by_id(u)
               @singleton ||= Store.new
            end

            def Store.find_all
               @singleton ||= Store.new
               [@singleton]
            end
#
#            def addNode(name)
#               node = Node.find_first_by_name(name)
#               unless node
#                  node = Node.create(:name => name, :last_updated_version => 0)
#               end
#               node
#            end
#
#            expose :addNode do |args|
#               args.declare :obj, :objId, :out, {}
#               args.declare :name, :sstr, :in, {}
#            end

            def getNode(name)
               node = Node.find_first_by_name(name)
               unless node
                  node = Node.create(:name => name, :last_updated_version => 0)
               end
               @node_name ||= name
               node
            end

            expose :getNode do |args|
               args.declare :obj, :objId, :out, {}
               args.declare :name, :sstr, :in, {}
            end

            def checkNodeValidity(name)
               node = Node.find_first_by_name(name)
               node
            end

            expose :checkNodeValidity do |args|
               args.declare :name, :sstr, :in, {}
               args.declare :obj, :objId, :out, {}
            end

            def raiseEvent(targets, need_restart, subsystems)
               node_map = {}
               targets.each do |name|
                  if name == @node_name
                     node = Node.find_first_by_name(name)
                     node_map[name] = node.last_updated_version
                  else
                     node_map[name] = 0
                  end
               end
               event = WallabyConfigEvent.new(node_map, need_restart, subsystems)
               event.bang!
            end

            expose :raiseEvent do |args|
               args.declare :targets, :list, :in, :desc=>"A map of targets:version"
               args.declare :need_restart, :bool, :in, :desc=>"Whether to restart the subsystem"
               args.declare :subsystems, :list, :in, :desc=>"A map of system:subsystem that should be acted upon"
            end
         end

         class Node
            include ::Rhubarb::Persisting
            include ::SPQR::Manageable
            qmf_package_name 'mrg.grid.config'
            qmf_class_name 'Node'

            declare_column :name, :string
            declare_column :last_checkin, :integer
            declare_column :last_updated_version, :integer


            alias def_last_checkin last_checkin
            alias def_last_updated_version last_updated_version

            def last_checkin
              def_last_checkin || 0
            end

            def last_updated_version
              def_last_updated_version || 0
            end

            qmf_property :name, :lstr, :index=>true
            qmf_property :last_checkin, :uint64
            qmf_property :last_updated_version, :uint64

            def getConfig(version)
               config["WALLABY_CONFIG_VERSION"] = version
               config
            end

            expose :getConfig do |args|
               args.declare :version, :uint64, :in, {}
               args.declare :config, :map, :out, {}
            end

            def setLastUpdatedVersion(version)
               self.last_updated_version = version
            end

            expose :setLastUpdatedVersion do |args|
               args.declare :version, :uint64, :in, {}
            end

            def checkin()
               self.last_checkin = ::Rhubarb::Util::timestamp
            end

            expose :checkin do |args|
            end

            private
            def config
               # XXX: put config here
               @config ||= {}
            end
         end

         class WallabyConfigEvent
            include ::SPQR::Raiseable
            arg :affectedNodes, :map, ""
            arg :restart, :bool, ""
            arg :targets, :list, ""

            qmf_class_name :WallabyConfigEvent
            qmf_package_name :WallabyConfigEvent
            qmf_severity :notice
         end
      end
   end
end


options = {}
options[:user] = "guest"
options[:password] = "guest"
options[:host] = "127.0.0.1"
options[:port] = 5672

Rhubarb::Persistence::open(":memory:")
Mrg::Grid::Config::Node.create_table

app = SPQR::App.new(options)
app.register Mrg::Grid::Config::Store,Mrg::Grid::Config::Node,Mrg::Grid::Config::WallabyConfigEvent

app.main
