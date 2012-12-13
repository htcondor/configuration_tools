require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'wallaby/spec_helper'

module Mrg
  module Grid
    module Config
      module Shell
        describe "CmdCCS" do

          before(:each) do
            hide_output
          end

          after(:each) do
            show_output
          end


          describe CCSList do
            store_entities.each do |ent|
              it "should call wallaby shell to list detailed information for #{ent}" do
                Object.const_set("CmdTester", Class.new(Mrg::Grid::Config::Shell::CCSList) { include CCSStubs })
                klass_name = Mrg::Grid::Config::Shell.constants.grep(/Show#{ent.to_s[0,4].capitalize}[a-z]*$/).to_s
                m = CmdTester.new
                m.entities[ent] = {"A"=>nil}
                m.should_receive(:run_wscmds).with([[Mrg::Grid::Config::Shell.const_get(klass_name), ["A"]]])
                m.act
              end
            end

            it "should provide verbose node configuration if verbose option given" do
                Object.const_set("CmdTester", Class.new(Mrg::Grid::Config::Shell::CCSList) { include CCSStubs })
                m = CmdTester.new
                m.entities[:Node] = {"A"=>nil}
                m.options[:verbose] = true
                m.should_receive(:run_wscmds).with([[Mrg::Grid::Config::Shell::ShowNode, ["A"]], [Mrg::Grid::Config::Shell::ShowNodeConfig, ["A"]]])
                m.act
            end
          end

          describe CCSListAll do
            store_entities.each do |ent|
              it "should call wallaby shell to list all #{ent}s" do
                Object.const_set("CmdTester", Class.new(Mrg::Grid::Config::Shell::CCSListAll) { include CCSStubs })
                m = CmdTester.new
                klass_name = Mrg::Grid::Config::Shell.constants.grep(/List#{ent.to_s[0,4].capitalize}[a-z]*$/).to_s
                m.should_receive(:run_wscmds).with([[Mrg::Grid::Config::Shell.const_get(klass_name), []]])
                m.entities[ent] = nil
                m.act
              end
            end
          end

          describe CCSDelete do
            store_entities.each do |ent|
              ["y", "n"].each do |ans|
                it "#{ans == "y" ? "should" : "should not"} continue if the user answers #{ans}" do
                  Object.const_set("CmdTester", Class.new(Mrg::Grid::Config::Shell::CCSDelete) { include CCSStubs })
                  m = CmdTester.new
                  klass_name = Mrg::Grid::Config::Shell.constants.grep(/Remove#{ent.to_s[0,4].capitalize}[a-z]*$/).to_s
                  STDIN.should_receive(:gets).and_return(ans)
                  if ans == "y"
                    m.should_receive(:run_wscmds).with([[Mrg::Grid::Config::Shell.const_get(klass_name), ["A"]]])
                  else
                    m.should_not_receive(:run_wscmds)
                  end
                  m.entities[ent] = {"A"=>nil}
                  m.act
                end
              end

              it "should not delete #{ent}s if the user accepts default response" do
                Object.const_set("CmdTester", Class.new(Mrg::Grid::Config::Shell::CCSDelete) { include CCSStubs })
                m = CmdTester.new
                klass_name = Mrg::Grid::Config::Shell.constants.grep(/Remove#{ent.to_s[0,4].capitalize}[a-z]*$/).to_s
                STDIN.should_receive(:gets).and_return("")
                m.should_not_receive(:run_wscmds)
                m.entities[ent] = {"A"=>nil}
                m.act
              end
            end
          end

          describe CCSAdd do
            before(:each) do
              @ccsops = CCSOpsTester.new
            end

            store_entities.each do |ent|
              it "should call wallaby shell commands to add then modify #{ent}s" do
                Object.const_set("CmdTester", Class.new(Mrg::Grid::Config::Shell::CCSAdd) { include CCSStubs })
                klass_name = Mrg::Grid::Config::Shell.constants.grep(/Add#{ent.to_s[0,4].capitalize}[a-z]*$/).to_s
                m = CmdTester.new
                m.stub(:run_cmdline)
                m.entities[ent] = {"A"=>nil}
                o = @ccsops.create_obj("A", ent)
                m.should_receive(:run_wscmds).with([[Mrg::Grid::Config::Shell.const_get(klass_name), ["A"]]] + @ccsops.send("update_#{ent.to_s.downcase}_cmds", o) + @ccsops.update_annotation(ent, o))
                m.act
              end
            end
          end

          describe CCSEdit do
            before(:each) do
              @store = Store.new
              @ccsops = CCSOpsTester.new
              setup_rhubarb
              Object.const_set("CmdTester", Class.new(Mrg::Grid::Config::Shell::CCSEdit) { include CCSStubs })
            end

            after(:each) do
              teardown_rhubarb
            end

            store_entities.each do |ent|
              it "should call wallaby shell commands to modify #{ent}s" do
                klass_name = Mrg::Grid::Config::Shell.constants.grep(/Add#{ent.to_s[0,4].capitalize}[a-z]*$/).to_s
                m = CmdTester.new
                # Wallaby seems to default annotations to nil instead of an
                # empty string.  Get around this by explicity setting the
                # annotation in the store
                e = add_entity("A", ent)
                e.setAnnotation("")
                m.store = @store
                m.stub(:run_cmdline)
                m.entities[ent] = {"A"=>nil}
                o = @ccsops.create_obj("A", ent)
                o.kind = "string" if o.respond_to?(:kind)
                o.membership = ["+++SKEL"] if ent == :Node
                m.should_receive(:run_wscmds).with(@ccsops.send("update_#{ent.to_s.downcase}_cmds", o) + @ccsops.update_annotation(ent, o))
                m.act
              end
            end
          end

        end
      end
    end
  end
end
