#!/usr/bin/ruby

require 'spqr/spqr'
require 'spqr/app'
require 'rhubarb/rhubarb'
require 'digest/md5'

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

            def getGroup(query)
               qentries = query.entries
               qkind, qkey = query.entries.pop
               qkind = qkind.upcase

               case qkind
               when "ID"
                 grp = Group.find(qkey)
                 return grp
               when "NAME"
                 grp = Group.find_first_by_name(qkey)
                 return grp
               end
            end

            expose :getGroup do |args|
               args.declare :obj, :objId, :out, "The object ID of the Group object corresponding to the requested group."
               args.declare :query, :map, :in, "A map from a query type to a query parameter. The queryType can be either 'ID' or 'Name'. 'ID' queryTypes will search for a group with the ID supplied as a parameter. 'Name' queryTypes will search for a group with the name supplied as a parameter."
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

            declare_table_name('nodegroup')
            declare_column :name, :string
            declare_column :is_identity_group, :boolean, :default, :false

            qmf_property :uid, :uint32, :index=>true
            qmf_property :is_identity_group, :bool
            qmf_property :name, :sstr, :desc=>"This group's name."
            qmf_property :features, :list, :desc=>"A list of features to be applied to this group, from highest to lowest priority."

            def features()
               @feature_list ||= []
            end

            def Group.DEFAULT_GROUP
               (Group.find_first_by_name("+++DEFAULT") or Group.create(:name => "+++DEFAULT"))
            end
         end

         class NodeMembership
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

            def idgroupname
               "+++#{Digest::MD5.hexdigest(self.name)}"
            end

            def id_group_init
               ig = Group.find_first_by_name(idgroupname)
               ig = Group.create(:name=>idgroupname, :is_identity_group=>true) unless ig
               ig
            end

            def memberships()
               db_memberships.map {|g| g.name}
            end

            def db_memberships
               NodeMembership.find_by(:node=>self).map{|nm| nm.grp}.select {|g| not g.is_identity_group}
            end

            qmf_property :memberships, :list, :desc=>"A list of the groups associated with this node, in inverse priority order (most important first), not including the identity group."

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

         class NodeMembership
            include ::Rhubarb::Persisting
            declare_column :node, :integer, references(Node, :on_delete=>:cascade)
            declare_column :grp, :integer, references(Group, :on_delete=>:cascade)
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
Mrg::Grid::Config::Group.create_table
Mrg::Grid::Config::NodeMembership.create_table

app = SPQR::App.new(options)
app.register Mrg::Grid::Config::Store,Mrg::Grid::Config::Node,Mrg::Grid::Config::NodeUpdatedNotice,Mrg::Grid::Config::Group

app.main
