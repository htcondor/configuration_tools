require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

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
          end


          it "should return the action" do
            @optester.action.should == @action
          end

          it "should return the command prefix" do
            @optester.cmd_prefix.should == @prefix
          end
        end
      end
    end
  end
end
