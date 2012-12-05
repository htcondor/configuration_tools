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
              @store = Store.new
              @optester.store = @store
              @store.addParam("EXIST")
              cmds = [[Mrg::Grid::Config::Shell::ModifyParam, ["NOEXIST"]], [Mrg::Grid::Config::Shell::ModifyParam, ["EXIST", "--level", "10"]]]
              lambda {@optester.run_wscmds(cmds)}.should_not raise_error(ShellCommandFailure)
              @optester.store.getParam("EXIST").level.should == 10
              teardown_rhubarb
            end
          end
        end
      end
    end
  end
end
