#!/usr/bin/ruby

require 'spqr/spqr'
require 'spqr/app'
require 'rhubarb/rhubarb'

module Mrg
   module Grid
      module Config
         class Store
            include ::SPQR::Manageable
            qmf_package_name 'com.redhat.grid.config'
            qmf_class_name 'Store'

            def Store.find_by_id(u)
               @singleton ||= Store.new
            end

            def Store.find_all
               @singleton ||= Store.new
               [@singleton]
            end

            qmf_property :apiVersionNumber, :uint32, :desc=>"The version of the API the store supports", :index=>false
            def apiVersionNumber
               20100804
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
                  node = Node.create(:name => name, :last_updated_version => 1)
               end
               @node_name ||= name
               node
            end

            expose :getNode do |args|
               args.declare :obj, :objId, :out, {}
               args.declare :name, :sstr, :in, {}
            end

            def getDefaultGroup
               return Group.DEFAULT_GROUP
            end

            expose :getDefaultGroup do |args|
               args.declare :obj, :objId, :out, "The object ID of the Group object corresponding to the default group."
            end

            def checkNodeValidity(names)
               names.reject {|n| Node.find_first_by_name(n)}
            end

            expose :checkNodeValidity do |args|
               args.declare :names, :list, :in, {}
               args.declare :invalidNodes, :list, :out, {}
            end

            def raiseEvent(targets)
               version = 0
               targets.each do |name|
                  if name == @node_name
                     node = Node.find_first_by_name(name)
                     version = node.last_updated_version
                  end
               end
               event = NodeUpdatedNotice.new
               event.nodes = targets
               event.version = version
               event.bang!
            end

            expose :raiseEvent do |args|
               args.declare :targets, :list, :in, :desc=>"A map of targets:version"
            end
         end

         class Group
            include ::Rhubarb::Persisting
            include ::SPQR::Manageable
            qmf_package_name 'com.redhat.grid.config'
            qmf_class_name 'Group'

            qmf_property :uid, :uint32, :index=>true
            qmf_property :is_identity_group, :bool
            qmf_property :name, :sstr, :desc=>"This group's name."
            qmf_property :features, :list, :desc=>"A list of features to be applied to this group, from highest to lowest priority."

            def features()
               self.feature_list
            end

            def Group.DEFAULT_GROUP
               (Group.find_first_by_name("+++DEFAULT") or Group.create(:name => "+++DEFAULT"))
            end
         end

         class Node
            include ::Rhubarb::Persisting
            include ::SPQR::Manageable
            qmf_package_name 'com.redhat.grid.config'
            qmf_class_name 'Node'

            declare_column :name, :string
            declare_column :last_checkin, :integer
            declare_column :last_updated_version, :integer
            declare_column :idgroup, :integer, references(Group)

            alias def_last_checkin last_checkin
            alias def_last_updated_version last_updated_version

            def last_checkin
              def_last_checkin || 0
            end

            def last_updated_version
              def_last_updated_version || 1
            end

            qmf_property :name, :lstr, :index=>true
            qmf_property :last_checkin, :uint64
            qmf_property :last_updated_version, :uint64
            qmf_property :identity_group, :objId, :desc=>"The object ID of this node's identity group"

            def identity_group
               self.idgroup ||= id_group_init
               self.idgroup
            end

            def id_group_init
               ig = Group.find_first_by_name(idgroupname)
               ig = Group.create(:name=>idgroupname, :is_identity_group=>true) unless ig
               ig
            end

            def getConfig(options)
               config["WALLABY_CONFIG_VERSION"] = options['version']
               config
            end

            expose :getConfig do |args|
               args.declare :options, :map, :in, {}
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

            def whatChanged(old_version, new_version)
               [[], [], []]
            end

            expose :whatChanged do |args|
               args.declare :old_version, :uint64, :in, "The old version."
               args.declare :new_version, :uint64, :in, "The new version."
               args.declare :params, :list, :out, "A list of parameters whose values changed between old_version and new_version."
               args.declare :restart, :list, :out, "A list of subsystems that must be restarted as a result of the changes between old_version and new_version."
               args.declare :affected, :list, :out, "A list of subsystems that must re-read their configurations as a result of the changes between old_version and new_version."
            end

            private
            def config
               # XXX: put config here
               @config ||= {}
            end
         end

         class NodeUpdatedNotice
            include ::SPQR::Raiseable
               arg :nodes, :map, "A map whose keys are the node names that must update."
               arg :version, :uint64, "The version of the latest configuration for these nodes."

            qmf_class_name :NodeUpdatedNotice
            qmf_package_name "com.redhat.grid.config"
            qmf_severity :notice
         end
      end
   end
end


options = {}
options[:appname] = "com.redhat.grid.config:Store"
options[:user] = "guest"
options[:password] = "guest"
options[:host] = "127.0.0.1"
options[:port] = 5672

Rhubarb::Persistence::open(":memory:")
Mrg::Grid::Config::Node.create_table

app = SPQR::App.new(options)
app.register Mrg::Grid::Config::Store,Mrg::Grid::Config::Node,Mrg::Grid::Config::NodeUpdatedNotice

app.main
