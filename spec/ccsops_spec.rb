require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'wallaby/spec_helper'

module Mrg
  module Grid
    module Config
      module Shell
        describe CCSOps do
          before(:each) do
            @tester = CCSOpsTester.new
            @store = Store.new
            @tester.store = @store
            @entn = "Characteristics"
            @fieldn = "Color"
            @fieldv = "Red"

            hide_output
          end

          after(:each) do
            show_output
          end

          describe "#parse_args" do
            store_entities.each do |ent|
              it "should accept #{ent} as an entity type and create a hash of the names" do
                CCSOpsTester.opname = "test-add"
                args = []
                for num in 1..2
                  args.push("#{ent}=#{ent}#{num}")
                end
                @tester.parse_args(*args)
                @tester.entities.keys.should include ent
                args.each do |a|
                  n = a.split('=')[1]
                  @tester.entities[ent].keys.should include n
                  @tester.entities[ent][n].should == nil
                end
              end
            end

            it "should raise an exception if no entities are specified" do
              lambda {@tester.parse_args()}.should raise_error(ShellCommandFailure)
            end

            it "should raise an exception if +++DEFAULT is provided" do
              CCSOpsTester.opname = "test-add"
              lambda {@tester.parse_args("Group=+++DEFAULT")}.should raise_error(ShellCommandFailure)
            end
          end

          describe "#create_obj" do
            store_entities.each do |ent|
              it "should create a specialized SerializedConfig object for a #{ent}" do
                obj = @tester.create_obj(ent.to_s, ent)
                obj.instance_of?(Mrg::Grid::SerializedConfigs.const_get(ent)).should == true
                obj.name.should == ent.to_s
                CCSOps.remove_fields(ent).each {|field| obj.instance_variables.should_not include "@#{field}"}
                @tester.send("add_#{ent.to_s.downcase}_fields").keys.each {|field| obj.instance_variables.should include "@#{field}"} if @tester.respond_to?("add_#{ent.to_s.downcase}_fields")
                obj.instance_variables.each {|v| v.instance_of?(Set).should == false}
              end
            end
          end

          [:Feature, :Node, :Subsystem].each do |ent|
            describe "#update_#{ent.to_s.downcase}_cmds" do
              before(:each) do 
                setup_rhubarb
                @inito = Mrg::Grid::Config.const_get(ent).create(:name=>@entn)
              end

              after(:each) do
                teardown_rhubarb
              end

              fields = get_fields(ent) - [:name, :annotation]
              [true, false].each do |qmfo|
                it "should generate replace commands for a #{ent} with #{qmfo ? "an empty" : "no"} object" do 
                  obj = qmfo ? @inito : nil
                  o = @tester.create_obj(@entn, ent, obj)
                  cmds = @tester.send("update_#{ent.to_s.downcase}_cmds", o)
                  fields.each {|var| cmds.should include [get_klass("Replace#{ent.to_s[0,4]}.*#{var.to_s[0,4].capitalize}"), [@entn]]}
                end
              end

              fields.each do |f|
                it "should generate replace commands for a #{ent} with a non-empty #{f} field in object" do 
                  @store.send(Mrg::Grid::MethodUtils.find_store_method("add.*#{param_type(ent, f.to_s).to_s[0,4].capitalize}"), @fieldn)
                  args = [@fieldn]
                  args = {@fieldn=>@fieldv} if arg_type(ent, f.to_s) == Hash
                  @inito.send(Mrg::Grid::Config.const_get(ent).set_from_get(Mrg::Grid::Config::Shell::QmfConversion.find_getter(f.to_s, ent.to_s)), "ADD", args, {})
                  o = @tester.create_obj(@entn, ent, @inito)
                  cmds = @tester.send("update_#{ent.to_s.downcase}_cmds", o)
                  cmd_arg = @inito.send(Mrg::Grid::Config::Shell::QmfConversion.find_getter(f.to_s, ent.to_s))
                  cmd_arg = [cmd_arg.to_a.join('=')] if arg_type(ent, f.to_s) == Hash
                  cmds.should include [get_klass("Replace#{ent.to_s[0,4]}.*#{f.to_s[0,4].capitalize}"), [@entn] + cmd_arg]
                end
              end

            end
          end

          describe "#update_group_cmds" do
            before(:each) do
              setup_rhubarb
              @store.addNode("node1")
              @store.addNode("node2")
              @targetg = "group1"
              @store.addExplicitGroup(@targetg)
              @o = @tester.create_obj(@targetg, :Group)
            end

            after(:each) do
              teardown_rhubarb
            end
            it "should add a node to a group" do
              @tester.orig_grps[@targetg] = @tester.deep_copy(@o)
              @o.members = ["node1"]
              cmds = @tester.update_group_cmds(@o)
              cmds.should include [Mrg::Grid::Config::Shell::AddNodeMembership, ["node1", @targetg]]
            end

            it "should remove a node from a group" do
              @o.members = ["node1"]
              @tester.orig_grps[@targetg] = @tester.deep_copy(@o)
              @o.members = []
              cmds = @tester.update_group_cmds(@o)
              cmds.should include [Mrg::Grid::Config::Shell::RemoveNodeMembership, ["node1", @targetg]]
            end

            it "should add and remove nodes from a group" do
              add_target = "node2"
              remove_target = "node1"
              @o.members = [remove_target]
              @tester.orig_grps[@targetg] = @tester.deep_copy(@o)
              @o.members = [add_target]
              cmds = @tester.update_group_cmds(@o)
              cmds.should include [Mrg::Grid::Config::Shell::AddNodeMembership, [add_target, @targetg]]
              cmds.should include [Mrg::Grid::Config::Shell::RemoveNodeMembership, [remove_target, @targetg]]
            end
          end

          describe "#update_parameter_cmds" do
            before(:each) do 
              setup_rhubarb
              @inito = Mrg::Grid::Config::Parameter.create(:name=>@entn)
            end

            after(:each) do
              teardown_rhubarb
            end

            arrays = [:conflicts, :depends]
            arrays.each do |attr|
              [true, false].each do |qmfo|
                it "should generate replace commands for a Parameter with #{qmfo ? "an empty" : "no"} object" do 
                  obj = qmfo ? @inito : nil
                  o = @tester.create_obj(@entn, :Parameter, obj)
                  cmds = @tester.update_parameter_cmds(o)
                  cmds.should include [get_klass("ReplaceParam#{attr.to_s[0,5].capitalize}"), [@entn]]
                end
              end

              it "should generate replace commands for a Parameter's #{attr} with an non-empty object field" do 
                list = ["Red", "Blue"]
                list.each {|p| @store.addParam(p)}
                @inito.send(Mrg::Grid::Config::Parameter.set_from_get(Mrg::Grid::Config::Shell::QmfConversion.find_getter(attr.to_s, "Parameter")), "ADD", list, {})
                o = @tester.create_obj(@entn, :Parameter, @inito)
                cmds = @tester.update_parameter_cmds(o)
                cmd = nil
                cmds.each {|c| cmd = c if c[0] == get_klass("ReplaceParam#{attr.to_s[0,5].capitalize}")}
                cmd.should_not == nil
                cmd[1].first.should == @entn
                list.each {|l| cmd[1].should include l}
              end
            end

            # Annotation is handled by update_annotation tests
            fields = get_fields(:Parameter) - [:name, :annotation] - arrays
            fields.each do |attr|
              it "should create a command to set the parameter's #{attr}" do
                bool_args = [:must_change, :needs_restart]
                value = "true"
                value = "1" if attr == :level
                @inito.send(Mrg::Grid::Config::Parameter.set_from_get(Mrg::Grid::Config::Shell::QmfConversion.find_getter(attr.to_s, "Parameter")), value)
                o = @tester.create_obj(@entn, :Parameter, @inito)
                cmds = @tester.update_parameter_cmds(o)
                cmd = []
                cmds.each {|c| cmd = c if c.first.to_s.include?("ModifyParam")}
                cmd.last.first.should == @entn
                loc = cmd.last.index("--#{attr.to_s.gsub(/_/, '-')}")
                loc.should_not == nil
                cmd.last[loc+1].should == value if not bool_args.include?(attr)
                cmd.last[loc+1].should == @tester.ws_bool(value) if bool_args.include?(attr)
              end
            end

            [:kind, :default_val, :description].each do |attr|
              it "should properly handle non-string data in the #{attr} field" do
                value = 0
                o = @tester.create_obj(@entn, :Parameter)
                o.send("#{attr}=", value)
                cmds = @tester.update_parameter_cmds(o)
                cmd = []
                cmds.each {|c| cmd = c if c.first.to_s.include?("ModifyParam")}
                cmd.last.first.should == @entn
                loc = cmd.last.index("--#{attr.to_s.gsub(/_/, '-')}")
                loc.should_not == nil
                cmd.last[loc+1].should == value.to_s
              end

              it "should properly handle nil data in the #{attr} field" do
                value = nil
                o = @tester.create_obj(@entn, :Parameter)
                o.send("#{attr}=", value)
                cmds = @tester.update_parameter_cmds(o)
                cmd = []
                cmds.each {|c| cmd = c if c.first.to_s.include?("ModifyParam")}
                cmd.last.first.should == @entn
                loc = cmd.last.index("--#{attr.to_s.gsub(/_/, '-')}")
                loc.should_not == nil
                cmd.last[loc+1].should == value.to_s
              end
            end
          end

          describe "#compare_objs" do
            it "should fail if obj class is different" do
              o1 = @tester.create_obj("Name", :Parameter)
              o2 = @tester.create_obj("Name", :Group)
              @tester.compare_objs(o1, o2).should == false
            end

            it "should fail if obj name is different" do
              o1 = @tester.create_obj("Name1", :Parameter)
              o2 = @tester.create_obj("Name2", :Parameter)
              @tester.compare_objs(o1, o2).should == false
            end

            it "should succeed if obj name and class are the same" do
              o1 = @tester.create_obj("Name", :Parameter)
              o2 = @tester.create_obj("Name", :Parameter)
              @tester.compare_objs(o1, o2).should == true
            end

            it "should detect if edited obj is missing a field" do
              type = :Parameter
              klass = Mrg::Grid::SerializedConfigs.const_get(type)
              o1 = @tester.create_obj("Name", type)
              orig_fields = klass.saved_fields.clone
              klass.saved_fields.delete(:level)
              o2 = klass.new
              o2.name = "Name"
              klass.field :level, orig_fields[:level]
              @tester.compare_objs(o1, o2).should == false
            end

            it "should detect if edited obj has an extra field" do
              type = :Parameter
              klass = Mrg::Grid::SerializedConfigs.const_get(type)
              o1 = @tester.create_obj("Name", type)
              klass.field :extra, String
              o2 = klass.new
              o2.name = "Name"
              klass.saved_fields.delete(:extra)
              @tester.compare_objs(o1, o2).should == false
            end

            store_entities.each do |type|
              cant_change = [Hash, Array]
              ref_obj = CCSOpsTester.new.create_obj("Name", type)
              ref_obj.instance_variables.each do |var|
                if cant_change.include?(ref_obj.instance_variable_get(var).class)
                  it "should recognize 1st #{type} object #{var.gsub(/@/, '')} metadata change from #{ref_obj.instance_variable_get(var).class}" do
                    o1 = @tester.create_obj("Name", type)
                    o2 = @tester.create_obj("Name", type)
                    o1.send("#{var.gsub(/@/, '')}=", "string")
                    @tester.compare_objs(o1, o2).should == false
                  end

                  it "should recognize 2nd #{type} object #{var.gsub(/@/, '')} metadata change from #{ref_obj.instance_variable_get(var).class}" do
                    o1 = @tester.create_obj("Name", type)
                    o2 = @tester.create_obj("Name", type)
                    o2.send("#{var.gsub(/@/, '')}=", "string")
                    @tester.compare_objs(o1, o2).should == false
                  end
                end
              end
            end
          end

          describe "#remove_invalid_entries" do
            store_entities.each do |invalid|
              store_entities.each do |ent|
                it "should remove invalid #{invalid}s from a #{ent}" do
                  prefix = "Invalid"
                  o = @tester.create_obj("Test", ent)
                  populate_fields(o, ent, prefix)
                  @tester.invalids[invalid] = ["#{prefix}#{invalid}"]
                  @tester.remove_invalid_entries(o)
                  rel_fields[ent].each do |get|
                    if get.field_type == invalid
                      v = o.send(get.method)
                      v.keys.should_not include "#{prefix}#{invalid}" if v.instance_of?(Hash)
                      v.should_not include "#{prefix}#{invalid}" if not v.instance_of?(Hash)
                    end
                  end
                end
              end
            end
          end

          describe "#verify_obj" do
            before(:each) do 
              setup_rhubarb
            end

            after(:each) do
              teardown_rhubarb
            end

            store_entities.each do |ent|
              it "should identify all invalid names on a #{ent} if the invalid name is not part of original working set" do
                prefix = "Invalid"
                o = @tester.create_obj("Test", ent)
                populate_fields(o, ent, prefix)
                invs = @tester.verify_obj(o)
                rel_fields[ent].each do |get|
                  invs[get.field_type].should include "#{prefix}#{get.field_type}"
                end
              end

              it "should not identify all invalid names on a #{ent} if the invalid name is part of original working set" do
                prefix = "Invalid"
                o = @tester.create_obj("Test", ent)
                rel_fields[ent].each do |get|
                  @tester.entities[get.field_type] = {"#{prefix}#{get.field_type}"=>nil}
                end
                populate_fields(o, ent, prefix)
                invs = @tester.verify_obj(o)
                rel_fields[ent].each do |get|
                  invs[get.field_type].should_not include "#{prefix}#{get.field_type}" if invs.has_key?(get.field_type)
                end
              end
            end
          end

          describe "#sync_memberships" do
            before(:each) do 
              @group1 = @tester.create_obj("group1", :Group)
              @group2 = @tester.create_obj("group2", :Group)
              @node1 = @tester.create_obj("node1", :Node)
              @node2 = @tester.create_obj("node2", :Node)
              @tester.pre_edit[:Node] = {@node1.name=>@tester.deep_copy(@node1),
                                         @node2.name=>@tester.deep_copy(@node2)}
              @tester.pre_edit[:Group] = {@group1.name=>@tester.deep_copy(@group1),
                                          @group2.name=>@tester.deep_copy(@group2)}
            end

            [:Node, :Group].each do |type|
              it "should detect a #{type == :Node ? "Group" : "Node"} added to a #{type}" do
                @node1.membership = [@group1.name] if type == :Node
                @group1.members = [@node1.name] if type == :Group
                @tester.entities[:Node] = {@node1.name=>@node1}
                @tester.entities[:Group] = {@group1.name=>@group1}
                @tester.sync_memberships
                @group1.members.should include @node1.name
                @node1.membership.should include @group1.name
              end

              it "should detect a #{type == :Node ? "Group" : "Node"} removed from a #{type}" do
                @tester.pre_edit[:Node][@node1.name].membership = [@group1.name]
                @tester.pre_edit[:Group][@group1.name].members = [@node1.name]
                @node1.membership = [] if type == :Node
                @group1.members = [] if type == :Group
                @tester.sync_memberships
                @node1.membership.should_not include @group1.name
                @group1.members.should_not include @node1.name
              end
            end
          end

          describe "#gen_update_cmds" do
            store_entities.each do |ent|
              it "should call the appropriate update function for each #{ent}" do
                objs = []
                for n in 1..2
                  @tester.entities[ent] = {} if not @tester.entities.has_key?(ent)
                  objs.push(@tester.create_obj("#{ent}#{n}", ent))
                  o = objs.last
                  @tester.orig_grps.merge!({o.name=>@tester.deep_copy(o)})
                  o.members = ["Node1", "Node2"] if o.respond_to?(:members)
                  @tester.entities[ent].merge!({o.name=>o})
                end
                @tester.gen_update_cmds 
                objs.each {|o| @tester.cmds.should include @tester.send("update_#{ent.to_s.downcase}_cmds", o).last}
              end
            end
          end

          describe "#edit_objs" do
            it "should accept non-string parameter values on features" do
              setup_rhubarb
              @store.addFeature("Name")
              @store.addParam("Integer")
              obj1 = @tester.create_obj("Name", :Feature)
              obj1.params = {"Integer"=>10}
              @tester.entities[:Feature] = {"Name"=>obj1}
              obj1.params = {"Integer"=>20}
              @tester.should_receive(:run_editor).and_return([obj1])
              @tester.edit_objs
              @tester.entities[:Feature]["Name"].should == obj1
              @tester.entities[:Feature]["Name"].params["Integer"].should == 20
              @tester.entities[:Feature]["Name"].params["Integer"].instance_of?(String).should == false
              teardown_rhubarb
            end

            it "should not create an empty entity if name field is deleted" do
              o1 = @tester.create_obj("Name", :Parameter)
              klass = Mrg::Grid::SerializedConfigs::Parameter
              orig_fields = klass.saved_fields.clone
              klass.saved_fields.delete(:name)
              o2 = klass.new
              @tester.entities[:Parameter]["Name"] = o1
              STDIN.should_receive(:gets).exactly(1).times.and_return("")
              @tester.should_receive(:run_editor).exactly(2).times.and_return([o2], [o1])
              klass.field :name, orig_fields[:name]
              @tester.edit_objs
              @tester.entities[:Parameter].keys.length.should == 1
            end

            it "should reject the user adding an entity to the list" do
              o1 = @tester.create_obj("Name", :Parameter)
              o2 = @tester.create_obj("Bad", :Parameter)
              @tester.entities[:Parameter]["Name"] = o1
              STDIN.should_receive(:gets).exactly(1).times.and_return("")
              @tester.should_receive(:run_editor).exactly(2).times.and_return([o1, o2], [o1])
              @tester.edit_objs
              @tester.entities[:Parameter].keys.length.should == 1
            end

            it "should reject the user removing an entity from the list" do
              o1 = @tester.create_obj("Name", :Parameter)
              o2 = @tester.create_obj("Name2", :Parameter)
              @tester.entities[:Parameter]["Name"] = o1
              @tester.entities[:Parameter]["Name2"] = o2
              STDIN.should_receive(:gets).exactly(1).times.and_return("")
              @tester.should_receive(:run_editor).exactly(2).times.and_return([o1], [o1,o2])
              @tester.edit_objs
              @tester.entities[:Parameter].keys.length.should == 2
            end

            it "should notify and re-edit if empty list" do
              o1 = @tester.create_obj("Name", :Parameter)
              @tester.entities[:Parameter]["Name"] = o1
              STDIN.should_receive(:gets).exactly(1).times.and_return("")
              @tester.should_receive(:run_editor).exactly(2).times.and_return([], [o1])
              @tester.edit_objs
            end
          end

          describe "#update_annotation" do
            store_entities.each do |ent|
              supports_annotation = Mrg::Grid::SerializedConfigs.const_get(ent).saved_fields.include?(:annotation) && (Mrg::Grid::Config::Shell.constants.grep(/Modify#{ent.to_s.capitalize[0..4]}/).first != nil)
              value = "Test"
              name = "EntName"
              it "should #{supports_annotation ? "create" : "not create"} commands to update a #{ent} annotation" do
                o = @tester.create_obj(name, ent)
                o.annotation = value
                cmd = @tester.update_annotation(ent, o)
                if supports_annotation
                  loc = cmd[0].last.index("--annotation")
                  cmd[0].last.first.should == name
                  loc.should_not == nil
                  cmd[0].last[loc+1].should == value
                else
                  cmd.should == []
                end
              end
            end
          end
        end
      end
    end
  end
end
