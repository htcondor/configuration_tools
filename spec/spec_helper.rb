$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'spec'
require 'spec/mocks'
require 'spec/autorun'
require 'spec/matchers'

require 'condor_wallaby/commandargs'


Spec::Runner.configure do |config|

end 

Spec::Matchers.define :exit_with_code do |exp_code|
  actual = nil
  match do |block|
    begin
      block.call
    rescue ExitStub::ShellError => e
      actual = e.status
    end
    actual and actual == exp_code
  end
  failure_message_for_should do |block|
    "expected block to call exit(#{exp_code}) but exit" +
      (actual.nil? ? " not called" : "(#{actual}) was called")
  end
  failure_message_for_should_not do |block|
    "expected block not to call exit(#{exp_code})"
  end
  description do
    "expect block to call exit(#{exp_code})"
  end
end

module Callbacks
  module CallbackFunctions
    def callbacks
      @c ||= Hash.new {|h,k| h[k] = []}
    end

    def register_callback(where, func)
      callbacks[where].push(func)
    end
  end

  def self.included(receiver)
    receiver.extend CallbackFunctions
  end
end

module ExitStub
  class ShellError < RuntimeError
    attr_accessor :status, :message
  end

  def exit!(status, message=nil)
    e = ShellError.new
    e.status = status
    e.message = message
    raise e
  end
end

class TestClass
  include Callbacks

  def self.cmd_args
    ["arg1", "arg2"]
  end
  include Wallaroo::Shell::CommandArgs
end

class TestClass2
  def self.cmd_args
    ["arg-name1", "arg-name2"]
  end
  include Wallaroo::Shell::CommandArgs
end

class TestClass3
  include Wallaroo::Shell::CommandArgs
  include ExitStub

  def initialize
    config[:name] = "from_config"
    config[:include] = "ConfigInclude"
    @fdata = {"from_config" => {:var=>"value", :include=>"FileInclude"}}
    @options = {:infile=>"filename"}
  end

  def env_prefix
    "FROM_ENV"
  end

  def def_include
    "DefaultInclude"
  end
end


#module OpNameStub
#  module OpStubs
#    def opname=(name)
#      @on = name
#    end
#
#    def opname
#      @on
#    end
#  end
#
#  def self.included(receiver)
#    receiver.extend OpStubs
#  end
#end
#
#class UtilsTester
#  include Mrg::Grid::Config::Shell::ToolUtils
#  include OpNameStub
#  include ExitStub
#
#  def store=(s)
#    @store=s
#  end
#
#  def store
#    @store
#  end
#end
#
#module CCSStubs
#  include ExitStub
#
#  def initialize
#    @orig_grps = {}
#    @entities = Hash.new {|h,k| h[k] = Hash.new {|h1,k1| h1[k1] = {}}}
#    @cmds = []
#    @options = {}
#  end
#
#  def entities
#    @entities
#  end
#
#  def pre_edit
#    @pre_edit ||= {}
#  end
#
#  def orig_grps
#    @orig_grps ||= {}
#  end
#
#  def invalids
#    @invalids ||= {}
#  end
#
#  def store=(storeclient)
#    @store = storeclient
#  end
#
#  def store
#    @store
#  end
#
#  def cmds
#    @cmds ||= []
#  end
#
#  def options
#    @options ||= {}
#  end
#end
#
#class CCSOpsTester < UtilsTester
#  include Mrg::Grid::Config::Shell::CCSOps
#  include CCSStubs
#end
#
#
#module CCPStubs
#  include ExitStub
#
#  def initialize
#    @options = {}
#    @cmds = []
#  end
#
#  def options
#    @options
#  end
#
#  def options=(value)
#    @options = value
#  end
#
#  def store=(storeclient)
#    @store = storeclient
#  end
#
#  def store
#    @store
#  end
#
#  def target=(t)
#    @target=t
#  end
#
#  def target
#    @target
#  end
#
#  def edit_parameters
#    @eparams ||= {}
#  end
#
#  def edit_features
#    @efeatures ||= []
#  end
#end
#
#class CCPOpsTester < UtilsTester
#  include Mrg::Grid::Config::Shell::CCPOps
#  include CCPStubs
#end
#
#def target
#  t = @cmd_target == "Node" ? "Node=" :  "Group="
#  t << "#{self.instance_variable_get("@#{@cmd_target.downcase}")}" if not @cmd_target.include?('_')
#  t << "+++#{@cmd_target.split('_')[0].upcase}" if @cmd_target.include?('_')
#  t
#end
#
#def obj
#  ns = target.split('=')
#  ns.first == "Node" ? @store.getNode(ns.last).identity_group : @store.getGroupByName(ns.last)
#end

def hide_output
  if !ENV['RSPEC_SHOW_OUTPUT']
    @old_stdout = $stdout.dup
    @old_stderr = $stderr.dup
    $stdout = File.open("/dev/null", "w")
    $stderr = File.open("/dev/null", "w")
  end
end

def show_output
  if !ENV['RSPEC_SHOW_OUTPUT']
    $stdout = @old_stdout.dup
    $stderr = @old_stderr.dup
  end
end

def get_klass(regex)
  Mrg::Grid::Config::Shell.const_get(Mrg::Grid::Config::Shell.constants.grep(/#{regex}/).first)
end

#def arg_type(type, func)
#  t = Array
#  t = Hash if (type == :Feature) && (func.downcase.include?("param"))
#  t
#end
#
#def param_type(type, field)
#  t = type
#  t = :Parameter if field.downcase.include?("param")
#  t = :Group if field.downcase.include?("membership")
##  t = :Node if field.downcase.include?("membership")
##  t = :Group if field.downcase.include?("memberships")
#  t
#end
#
#def get_fields(type)
#  Mrg::Grid::SerializedConfigs.const_get(type).public_instance_methods(false).select {|m| not m.include?('=')}.collect {|m| m.to_sym} - Mrg::Grid::Config::Shell::CCSOps.remove_fields(type)
#end

def store_entities
  [:Feature, :Group, :Node, :Parameter, :Subsystem]
end

#def rel_fields
#  meta = Struct.new(:field_type, :method)
#  {:Parameter=>[meta.new(:Parameter, :conflicts), meta.new(:Parameter, :depends)],
#   :Subsystem=>[meta.new(:Parameter, :params)],
#   :Group=>[meta.new(:Parameter, :params), meta.new(:Node, :members), meta.new(:Feature, :features)],
#   :Node=>[meta.new(:Group, :membership)],
#   :Feature=>[meta.new(:Parameter, :params), meta.new(:Feature, :included), meta.new(:Feature, :conflicts), meta.new(:Feature, :depends)]}
#end
#
#def populate_fields(obj, type, pre)
#  if type == :Parameter
#    obj.conflicts = ["#{pre}Parameter"]
#    obj.depends = ["#{pre}Parameter"]
#  end
#  if type == :Subsystem
#    obj.params = ["#{pre}Parameter"]
#  end
#  if type == :Group
#    obj.members = ["#{pre}Node"]
#    obj.params = {"#{pre}Parameter"=>"blah"}
#    obj.features = ["#{pre}Feature"]
#  end
#  if type == :Node
#    obj.membership = ["#{pre}Group"]
#  end
#  if type == :Feature
#    obj.params = {"#{pre}Parameter"=>"blah"}
#    obj.included = ["#{pre}Feature"]
#    obj.conflicts = ["#{pre}Feature"]
#    obj.depends = ["#{pre}Feature"]
#  end
#end
#
def add_entity(name, type)
  @store.send(Mrg::Grid::MethodUtils.find_store_method(/add\w*#{type.to_s[0,4].capitalize}/), name)
end

#def verify_cmd_params(type, cmd_act)
#  CCPOpsTester.opname = "test-#{cmd_act}"
#  args = []
#  for num in 1..2
#    args.push("#{type}=#{type}#{num}")
#  end
#  @store.addNode(@name)
#  @tester.parse_args("Node=#{@name}", *args)
#  list = @tester.send("#{cmd_act}_#{type.to_s.downcase}s")
#  args.each do |a|
#    list.empty?.should_not == true
#    list.keys.should include a.split('=')[1] if list.instance_of?(Hash)
#    list.should include a.split('=')[1] if list.instance_of?(Array)
#  end
#end
#
#def make_obj(name, type)
#  obj = Mrg::Grid::SerializedConfigs.const_get(type).new
#  obj.name = name
#  obj.instance_variables.collect{|n| n.delete("@")}.each do |m|
#    if obj.send(m).instance_of?(Set)
#      obj.send("#{m}=", [])
#    end
#  end
#  obj
#end
#
def save_all_meta
  # Need to save metadata for SerializedConfigs objects because
  # create_obj modifies them.
  @saved_meta = {}
  store_entities.each do |ent|
    @saved_meta[ent] = Mrg::Grid::SerializedConfigs.const_get(ent).saved_fields.clone
  end
end

def restore_all_meta
  # Restore the saved metadata for SerializedConfigs objects
  store_entities.each do |ent|
  klass = Mrg::Grid::SerializedConfigs.const_get(ent)
    @saved_meta[ent].each_pair do |key, value|
      klass.field key, value
    end
  end
end
