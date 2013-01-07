require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'wallaby/spec_helper'

module Mrg
  module Grid
    module Config
      module Shell
        describe "CmdCCP" do
          include BaseDBFixture

          before(:each) do
            setup_rhubarb
            @store = Store.new
            reconstitute_db
            @node = "nodename"
            @group = "groupname"
            @parameter = "CONDOR_HOST"
            @feature = "ExecuteNode"
            @store.addNode(@node)
            @store.addExplicitGroup(@group)

            hide_output
          end

          after(:each) do
            show_output
            teardown_rhubarb
          end

          [:CCPAdd, :CCPInsert, :CCPRemove].each do |klass|
            [:Node, :Group, :Default_Group, :Skel_Group].each do |tar|
              [:Feature, :Parameter].each do |ent|
                it "should #{klass.to_s.split('CCP').last.downcase} a #{ent} on #{tar.to_s.gsub(/_/, '')}" do
                  @cmd_target = tar.to_s
                  e = ent.to_s
                  name = self.instance_variable_get("@#{e.downcase}")
                  input = []
                  input.push("localhost") if (ent == :Parameter) && (klass != :CCPRemove)
                  input += ["y", "n", "n"]
                  if klass == :CCPRemove
                    m = Mrg::Grid::MethodUtils.find_method("modify#{e[0..4].capitalize}", "Group").first.to_sym
                    arg = ent == :Parameter ? {name=>"localhost"} : [name]
                    obj.send(m, "ADD", arg, {})
                  end
                  STDIN.should_receive(:gets).and_return(*input)
                  Mrg::Grid::Config::Shell.const_get(klass).new(@store, "").main([target, "#{ent}=#{name}"])
                  getter = Mrg::Grid::MethodUtils.find_property("#{e[0..4].downcase}", "Group")[0]
                  obj.send(getter).should include name if (ent == :Feature) && (klass != :CCPRemove)
                  obj.send(getter).keys.should include name if (ent == :Parameter) && (klass != :CCPRemove)
                  obj.send(getter).should_not include name if (ent == :Feature) && (klass == :CCPRemove)
                  obj.send(getter).keys.should_not include name if (ent == :Parameter) && (klass == :CCPRemove)
                end
              end

              it "should #{klass.to_s.split('CCP').last.downcase} both features and parameters on #{tar.to_s.gsub(/_/, '')}" do
                @cmd_target = tar.to_s
                input = []
                input.push("localhost") if klass != :CCPRemove
                input += ["y", "n", "n"]
                if klass == :CCPRemove
                  obj.modifyFeatures("ADD", [@feature], {})
                  obj.modifyParams("ADD", {@parameter=>"localhost"}, {})
                end
                STDIN.should_receive(:gets).and_return(*input)
                Mrg::Grid::Config::Shell.const_get(klass).new(@store, "").main([target, "Feature=#{@feature}", "Parameter=#{@parameter}"])
                if klass != :CCPRemove
                  obj.features.should include @feature
                  obj.params.keys.should include @parameter
                else
                  obj.features.should_not include @feature
                  obj.params.keys.should_not include @parameter
                end
              end

              it "should not apply changes when doing #{klass.to_s.split('CCP').last.downcase} on #{tar.to_s.gsub(/_/, '')} if user declines to apply" do
                @cmd_target = tar.to_s
                obj.modifyFeatures("ADD", [@feature], {}) if klass == :CCPRemove
                STDIN.should_receive(:gets).and_return("n")
                Mrg::Grid::Config::Shell.const_get(klass).new(@store, "").main([target, "Feature=#{@feature}"])
                obj.features.should_not include @feature if klass != :CCPRemove
                obj.features.should include @feature if klass == :CCPRemove
              end
            end
          end

          [:CCPAdd, :CCPInsert].each do |klass|
            it "should add features at the #{klass == :CCPAdd ? "lowest" : "highest"} priority" do
              g = @store.getGroupByName(@group)
              g.modifyFeatures("ADD", ["Master", "NodeAccess"], {})
              STDIN.should_receive(:gets).and_return("y", "n", "n")
              Mrg::Grid::Config::Shell.const_get(klass).new(@store, "").main(["Group=#{@group}", "Feature=#{@feature}"])
              g = @store.getGroupByName(@group)
              g.features.last.should == @feature if klass == :CCPAdd
              g.features.first.should == @feature if klass == :CCPInsert
            end
          end

          it "should create a snapshot with the provided name" do
            snap_name = "TestSnap"
            STDIN.should_receive(:gets).and_return("y", "y", snap_name, "n")
            Mrg::Grid::Config::Shell::CCPAdd.new(@store, "").main(["Group=#{@group}", "Feature=#{@feature}"])
            Snapshot.find_first_by_name(snap_name).should_not == nil
          end

          it "should not allow an empty snapshot name" do
            STDIN.should_receive(:gets).and_return("y", "y", "", "n", "n")
            Mrg::Grid::Config::Shell::CCPAdd.new(@store, "").main(["Group=#{@group}", "Feature=#{@feature}"])
          end

          it "should create a snapshot when successfully activated" do
            STDIN.should_receive(:gets).and_return("y", "*", "*", "localhost", "y", "n", "y")
            @store.should_receive(:activateConfig).and_return({})
            Mrg::Grid::Config::Shell::CCPAdd.new(@store, "").main(["Group=#{@group}", "Feature=#{@feature}", "Feature=Master", "Feature=NodeAccess"])
            Snapshot.find_all.last.name.should include "Automatically generated snapshot at"
          end

          it "should not create a snapshot when activating if one was created in the same invocation" do
            snap_name = "TestSnap"
            STDIN.should_receive(:gets).and_return("y", "*", "*", "localhost", "y", "y", snap_name, "y")
            @store.should_receive(:activateConfig).and_return({})
            Mrg::Grid::Config::Shell::CCPAdd.new(@store, "").main(["Group=#{@group}", "Feature=#{@feature}", "Feature=Master", "Feature=NodeAccess"])
            Snapshot.find_all.each {|s| s.name.should_not include "Automatically generated snapshot at"}
            Snapshot.find_first_by_name(snap_name).should_not == nil
          end

          [:y, :n].each do |resp|
            it "should provide a warning if the ConsoleCollector feature is added and #{resp == :y ? "keep" : "remove"} it #{resp == :y ? "in" : "from"} the list if #{resp} is answered" do
              
              STDIN.should_receive(:gets).and_return(resp.to_s, "y", "n", "n")
              Mrg::Grid::Config::Shell::CCPAdd.new(@store, "").main(["Group=#{@group}", "Feature=ConsoleCollector", "Feature=ExecuteNode"])
              g = @store.getGroupByName(@group)
              g.features.should include "ExecuteNode"
              g.features.should include "ConsoleCollector" if resp == :y
              g.features.should_not include "ConsoleCollector" if resp == :n
            end
          end

          describe CCPEdit do
            before :each do
              Object.const_set("CmdTester", Class.new(Mrg::Grid::Config::Shell::CCPEdit) { include CCPStubs })
            end

            [:Feature, :Parameter].each do |opt|
              it "should ignore a list of #{opt}s provided on the command line when editing" do
                m = CmdTester.new
                m.store = @store
                m.target = {:Group=>@group}
                edits = m.send("edit_#{opt.to_s.downcase}s" )
                edits.push(@feature) if opt == :Feature
                edits[@parameter] = nil if opt == :Parameter
                m.should_receive(:run_editor).and_return(m.group_obj)
                STDIN.should_receive(:gets).exactly(3).times.and_return("y", "n", "n")
                m.act.should == 0
                if opt == :Parameter
                  @store.getGroupByName(@group).params.keys.should_not include @parameter
                else
                  @store.getGroupByName(@group).features.should_not include @feature
                end
              end
            end

            [:schedds, :qmf].each do |opt|
              it "should ignore the #{opt} option when editing" do
                m = CmdTester.new
                m.store = @store
                m.target = {:Group=>@group}
                m.options[opt] = true
                m.should_receive(:run_editor).and_return(m.group_obj)
                STDIN.should_receive(:gets).exactly(3).times.and_return("y", "n", "n")
                m.act.should == 0
              end
            end

            it "should not prompt for a value for parameters added in the editor" do
              v = "value"
              m = CmdTester.new
              m.store = @store
              m.target = {:Group=>@group}
              o = m.group_obj
              o.params[@parameter] = v
              m.should_receive(:run_editor).and_return(o)
              STDIN.should_receive(:gets).exactly(3).times.and_return("y", "n", "n")
              m.act.should == 0
            end

            it "should prompt for a value for parameters required by features added in the editor" do
              v = "localhost"
              f = "Master"
              p = "CONDOR_HOST"
              m = CmdTester.new
              m.store = @store
              m.target = {:Group=>@group}
              o = m.group_obj
              o.features.push("Master")
              m.should_receive(:run_editor).and_return(o)
              STDIN.should_receive(:gets).exactly(5).times.and_return("y", v, "y", "n", "n")
              m.act.should == 0
              qmfo = @store.getGroupByName(@group)
              qmfo.features.should include f
              qmfo.params.keys.should include p
              qmfo.params[p].should == v
            end
          end
        end
      end
    end
  end
end
