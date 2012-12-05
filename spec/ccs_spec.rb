require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'condor_wallaby/ccs'

module Mrg
  module Grid
    module Config
      describe CCS do
        before(:each) do
          @features = "F1,f2,F3"
          @params = "P1,p2,p3"
          @nodes = "N1,n2"
          @groups = "G1,g2"
          @subsystems = "S1,s2"
          @host = "localhost"

          hide_output
        end

        after(:each) do
          show_output
        end

        describe "arg parsing" do
          before(:each) do
            @ccs_act = ["-a"]
            @ccs_ent = ["-f", @features]
            @ccs_args = @ccs_act + @ccs_ent
            @cmd_feat_args = @features.split(',').collect {|f| "Feature=#{f}"}
            @ws_cmd = ["ccs-add"]
            @common_cmd_args = @ws_cmd + @cmd_feat_args
          end

          describe "for wallaby shell options" do
            [[:b, :broker, :H], [:o, :port, :p], [:U, :user, :U], [:P, :password, :P], [:m, :auth_mechanism, :M]].each do |short, long, ws_arg|
              it "should pass -#{short} to wallaby shell as -#{ws_arg}" do
                arg = "ANONYMOUS"
                arg = 1 if short == :o
                Mrg::Grid::Config::Shell.should_receive(:main).with(["-#{ws_arg}", arg, *@common_cmd_args])
                Mrg::Grid::Config::CCS.new.main(["-#{short}", arg.to_s] + @ccs_args)
              end

              it "should pass --#{long} to wallaby shell as -#{ws_arg}" do
                arg = "ANONYMOUS"
                arg = 1 if short == :o
                Mrg::Grid::Config::Shell.should_receive(:main).with(["-#{ws_arg}", arg, *@common_cmd_args])
                Mrg::Grid::Config::CCS.new.main(["--#{long.to_s.gsub(/_/, '-')}", arg.to_s] + @ccs_args)
              end
            end
          end

          describe "for non-wallaby shell options" do
            [:verbose, :v].each do |opt|
              ccs_opt = "verbose"
              it "should pass option #{opt} to ccs" do
                Mrg::Grid::Config::Shell.should_receive(:main).with(@ws_cmd + ["--#{ccs_opt}"] + @cmd_feat_args)
                Mrg::Grid::Config::CCS.new.main(["-#{opt == :v ? opt : "-#{opt}"}"] + @ccs_args)
              end
            end
          end

          describe "for targets" do
            store_entities.each do |ent|
              it "should handle #{ent.to_s.downcase} names with commas" do
                name = "name,with,comma"
                Mrg::Grid::Config::Shell.should_receive(:main).with(@ws_cmd + ["#{ent}=#{name}"])
                Mrg::Grid::Config::CCS.new.main(@ccs_act + ["-#{ent.to_s[0,1].downcase}", "\"#{name}\""])
              end

              it "should separate comma delimited list of #{ent.to_s.downcase}s into multiple args with long option" do
                name = self.instance_variables.grep(/@#{ent.to_s[0,1].downcase}/).first
                list = self.instance_variable_get(name)
                Mrg::Grid::Config::Shell.should_receive(:main).with(@ws_cmd + list.split(',').collect {|e| "#{ent}=#{e}"})
                Mrg::Grid::Config::CCS.new.main(@ccs_act + ["--#{(ent == :Parameter) || (ent == :Subsystem) ? "#{ent.to_s[0,5].downcase}s" : "#{ent.to_s.downcase}s"}", list])
              end

              it "should separate comma delimited list of #{ent.to_s.downcase}s into multiple args with short option" do
                name = self.instance_variables.grep(/@#{ent.to_s[0,1].downcase}/).first
                list = self.instance_variable_get(name)
                Mrg::Grid::Config::Shell.should_receive(:main).with(@ws_cmd + list.split(',').collect {|e| "#{ent}=#{e}"})
                Mrg::Grid::Config::CCS.new.main(@ccs_act + ["-#{ent.to_s[0,1].downcase}", list])
              end
            end
          end

          describe "for actions" do
            it "should require an action" do
              lambda {Mrg::Grid::Config::CCS.new.main(@ccs_ent)}.should raise_error
            end

            it "should only allow 1 action" do
              lambda {Mrg::Grid::Config::CCS.new.main(@ccs_act + @ccs_act + @ccs_ent)}.should raise_error
            end

            [:add, :delete, :edit, :list].each do |act|
              it "should convert #{act} into the ccs-#{act} command" do
                Mrg::Grid::Config::Shell.should_receive(:main).with(["ccs-#{act}"] + @cmd_feat_args)
                Mrg::Grid::Config::CCS.new.main(["--#{act}"] + @ccs_ent)
              end

              it "should convert #{act.to_s[0,1]} into the ccs-#{act} command" do
                Mrg::Grid::Config::Shell.should_receive(:main).with(["ccs-#{act}"] + @cmd_feat_args)
                Mrg::Grid::Config::CCS.new.main(["-#{act.to_s[0,1]}"] + @ccs_ent)
              end
            end
          end

          describe "for list actions" do
            store_entities.each do |lact|
              it "should call ccs-listall for #{lact.to_s.downcase}" do
                Mrg::Grid::Config::Shell.should_receive(:main).with(["ccs-listall", "#{lact}"])
                Mrg::Grid::Config::CCS.new.main(["--list-all-#{lact.to_s.downcase.gsub(/parameter/, "param")}s"])
              end

              it "should not allow action and list-all-#{lact.to_s.downcase}" do 
                lambda {Mrg::Grid::Config::CCS.new.main(@ccs_act + ["--list-all-#{lact.to_s.downcase.gsub(/parameter/, "param")}s"] + @ccs_ent)}.should raise_error
              end
            end
          end

        end
      end
    end
  end
end
