$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'spec'
require 'spec/mocks'
require 'spec/autorun'

require 'condor_wallaby/utils'

require 'condor_wallaby/commands/cmd_ccp'
require 'condor_wallaby/commands/cmd_ccs'

Spec::Runner.configure do |config|

end 
module OpNameStub
  module OpStubs
    def opname=(name)
      @on = name
    end

    def opname
      @on
    end
  end

  def self.included(receiver)
    receiver.extend OpStubs
  end
end

module ExitStub
  def exit!(status, message=nil)
    raise Mrg::Grid::Config::Shell::ShellCommandFailure.new
  end
end

class UtilsTester
  include Mrg::Grid::Config::Shell::ToolUtils
  include OpNameStub
end

module CCSStubs
  include ExitStub

  def initialize
    @orig_grps = {}
    @entities = {}
    @cmds = []
    @options = {}
  end

  def entities
    @entities ||= {}
  end

  def pre_edit
    @pre_edit ||= {}
  end

  def orig_grps
    @orig_grps ||= {}
  end

  def invalids
    @invalids ||= {}
  end

  def store=(storeclient)
    @store = storeclient
  end

  def store
    @store
  end

  def cmds
    @cmds ||= []
  end

  def options
    @options ||= {}
  end
end

class CCSOpsTester < UtilsTester
  include Mrg::Grid::Config::Shell::CCSOps
  include CCSStubs
end


class CCPOpsTester < UtilsTester
  include Mrg::Grid::Config::Shell::CCPOps
  include ExitStub

  def initialize
    @options = {}
  end

  def options
    @options
  end

  def options=(value)
    @options = value
  end

  def store=(storeclient)
    @store = storeclient
  end

  def store
    @store
  end

  def target=(t)
    @target=t
  end

  def target
    @target
  end
end

def target
  t = @cmd_target == "Node" ? "Node=" :  "Group="
  t << "#{self.instance_variable_get("@#{@cmd_target.downcase}")}" if not @cmd_target.include?('_')
  t << "+++#{@cmd_target.split('_')[0].upcase}" if @cmd_target.include?('_')
  t
end

def obj
  ns = target.split('=')
  ns.first == "Node" ? @store.getNode(ns.last).identity_group : @store.getGroupByName(ns.last)
end

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

def arg_type(type, func)
  t = Array
  t = Hash if (type == :Feature) && (func.downcase.include?("param"))
  t
end

def param_type(type, field)
  t = type
  t = :Parameter if field.downcase.include?("param")
  t = :Group if field.downcase.include?("membership")
#  t = :Node if field.downcase.include?("membership")
#  t = :Group if field.downcase.include?("memberships")
  t
end

def get_fields(type)
  Mrg::Grid::SerializedConfigs.const_get(type).public_instance_methods(false).select {|m| not m.include?('=')}.collect {|m| m.to_sym} - Mrg::Grid::Config::Shell::CCSOps.remove_fields(type)
end

def store_entities
  [:Feature, :Group, :Node, :Parameter, :Subsystem]
end

def rel_fields
  meta = Struct.new(:field_type, :method)
  {:Parameter=>[meta.new(:Parameter, :conflicts), meta.new(:Parameter, :depends)],
   :Subsystem=>[meta.new(:Parameter, :params)],
   :Group=>[meta.new(:Parameter, :params), meta.new(:Node, :members), meta.new(:Feature, :features)],
   :Node=>[meta.new(:Group, :membership)],
   :Feature=>[meta.new(:Parameter, :params), meta.new(:Feature, :included), meta.new(:Feature, :conflicts), meta.new(:Feature, :depends)]}
end

def populate_fields(obj, type, pre)
  if type == :Parameter
    obj.conflicts = ["#{pre}Parameter"]
    obj.depends = ["#{pre}Parameter"]
  end
  if type == :Subsystem
    obj.params = ["#{pre}Parameter"]
  end
  if type == :Group
    obj.members = ["#{pre}Node"]
    obj.params = {"#{pre}Parameter"=>"blah"}
    obj.features = ["#{pre}Feature"]
  end
  if type == :Node
    obj.membership = ["#{pre}Group"]
  end
  if type == :Feature
    obj.params = {"#{pre}Parameter"=>"blah"}
    obj.included = ["#{pre}Feature"]
    obj.conflicts = ["#{pre}Feature"]
    obj.depends = ["#{pre}Feature"]
  end
end

def add_entity(name, type)
  @store.send(Mrg::Grid::MethodUtils.find_store_method(/add\w*#{type.to_s[0,4].capitalize}/), name)
end

def verify_cmd_params(type, cmd_act)
  CCPOpsTester.opname = "test-#{cmd_act}"
  args = []
  for num in 1..2
    args.push("#{type}=#{type}#{num}")
  end
  @store.addNode(@name)
  @tester.parse_args("Node=#{@name}", *args)
  list = @tester.send("#{cmd_act}_#{type.to_s.downcase}s")
  args.each do |a|
    list.empty?.should_not == true
    list.keys.should include a.split('=')[1] if list.instance_of?(Hash)
    list.should include a.split('=')[1] if list.instance_of?(Array)
  end
end
