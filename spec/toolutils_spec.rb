require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'wallaby/spec_helper'

module Mrg
  module Grid
    module Config
      module Shell

        describe ToolUtils do
          before :each do
            @optester = UtilsTester.new
            @action = :add
            @prefix = :tester
            UtilsTester.opname = "#{@prefix}-#{@action}"
            hide_output
          end

          after :each do
            show_output
          end

          it "should return the action" do
            @optester.action.should == @action
          end

          it "should return the command prefix" do
            @optester.cmd_prefix.should == @prefix
          end

          describe "#run_wscmds" do
            include BaseDBFixture

            it "should continue running commands after an error" do
              new = 10
              setup_rhubarb
              ret = 0
              @store = Store.new
              @optester.store = @store
              @store.addParam("EXIST")
              cmds = [[Mrg::Grid::Config::Shell::ModifyParam, ["NOEXIST"]], [Mrg::Grid::Config::Shell::ModifyParam, ["EXIST", "--level", "10"]]]
              lambda {ret = @optester.run_wscmds(cmds)}.should_not raise_error(ShellCommandFailure)
              ret.should_not == 0
              @optester.store.getParam("EXIST").level.should == 10
              teardown_rhubarb
            end
          end

          describe "#compare_objs" do
            it "should fail if obj class is different" do
              o1 = make_obj("Name", :Parameter)
              o2 = make_obj("Name", :Group)
              @optester.compare_objs(o1, o2).should == false
            end

            it "should fail if obj name is different" do
              o1 = make_obj("Name1", :Parameter)
              o2 = make_obj("Name2", :Parameter)
              @optester.compare_objs(o1, o2).should == false
            end

            it "should succeed if obj name and class are the same" do
              o1 = make_obj("Name", :Parameter)
              o2 = make_obj("Name", :Parameter)
              @optester.compare_objs(o1, o2).should == true
            end

            it "should detect if edited obj is missing a field" do
              type = :Parameter
              klass = Mrg::Grid::SerializedConfigs.const_get(type)
              o1 = make_obj("Name", type)
              orig_fields = klass.saved_fields.clone
              klass.saved_fields.delete(:level)
              o2 = klass.new
              o2.name = "Name"
              klass.field :level, orig_fields[:level]
              @optester.compare_objs(o1, o2).should == false
            end

            it "should detect if edited obj has an extra field" do
              type = :Parameter
              klass = Mrg::Grid::SerializedConfigs.const_get(type)
              o1 = make_obj("Name", type)
              klass.field :extra, String
              o2 = klass.new
              o2.name = "Name"
              klass.saved_fields.delete(:extra)
              @optester.compare_objs(o1, o2).should == false
            end

            store_entities.each do |type|
              cant_change = [Hash, Array]
              ref_obj = make_obj("Name", type)
              ref_obj.instance_variables.each do |var|
                if cant_change.include?(ref_obj.instance_variable_get(var).class)
                  it "should recognize 1st #{type} object #{var.gsub(/@/, '')} metadata change from #{ref_obj.instance_variable_get(var).class}" do
                    o1 = make_obj("Name", type)
                    o2 = make_obj("Name", type)
                    o1.send("#{var.gsub(/@/, '')}=", "string")
                    @optester.compare_objs(o1, o2).should == false
                  end

                  it "should recognize 2nd #{type} object #{var.gsub(/@/, '')} metadata change from #{ref_obj.instance_variable_get(var).class}" do
                    o1 = make_obj("Name", type)
                    o2 = make_obj("Name", type)
                    o2.send("#{var.gsub(/@/, '')}=", "string")
                    @optester.compare_objs(o1, o2).should == false
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
