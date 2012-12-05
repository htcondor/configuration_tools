require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'condor_wallaby/ccp'

module Mrg
  module Grid
    module Config
      describe CCP do
        before(:each) do
          @features = "F1,f2,F3"
          @params = "P1,p2,p3"
          @node = "N"
          @group = "G"
          @host = "localhost"

          hide_output
        end

        after(:each) do
          show_output
        end

        describe "arg parsing" do
          before(:each) do
            @ccp_target = ["-n", @node]
            @ccp_act = ["-a"]
            @ccp_ent = ["-f", @features]
            @ccp_args = @ccp_act + @ccp_ent
            @cmd_feat_args = @features.split(',').collect {|f| "Feature=#{f}"}
            @ws_cmd = ["ccp-add"]
            @ws_target = ["Node=#{@node}"]
            @common_cmd_args = @ws_cmd + @ws_target + @cmd_feat_args
          end

          describe "for wallaby shell options" do
            [[:b, :broker, :H], [:o, :port, :p], [:U, :user, :U], [:P, :password, :P], [:m, :auth_mechanism, :M]].each do |short, long, ws_arg|
              it "should pass -#{short} to wallaby shell as -#{ws_arg}" do
                arg = "ANONYMOUS"
                arg = 1 if short == :o
                Mrg::Grid::Config::Shell.should_receive(:main).with(["-#{ws_arg}", arg, *@common_cmd_args])
                Mrg::Grid::Config::CCP.new.main(["-#{short}", arg.to_s] + @ccp_target + @ccp_args)
              end

              it "should pass --#{long} to wallaby shell as -#{ws_arg}" do
                arg = "ANONYMOUS"
                arg = 1 if short == :o
                Mrg::Grid::Config::Shell.should_receive(:main).with(["-#{ws_arg}", arg, *@common_cmd_args])
                Mrg::Grid::Config::CCP.new.main(["--#{long.to_s.gsub(/_/, '-')}", arg.to_s] + @ccp_target + @ccp_args)
              end
            end
          end

          describe "for non-wallaby shell options" do
            [:schedds, :qmfbroker, :verbose, :v].each do |opt|
              ccp_opt = opt.to_s.gsub(/broker/, '')
              ccp_opt = "verbose" if opt == :v
              it "should pass option #{opt} to ccp" do
                Mrg::Grid::Config::Shell.should_receive(:main).with(@ws_cmd + ["--#{ccp_opt}"] + @ws_target + @cmd_feat_args)
                Mrg::Grid::Config::CCP.new.main(["-#{opt == :v ? opt : "-#{opt}"}"] + @ccp_target + @ccp_args)
              end
            end
          end

          describe "for targets" do
            [:default_group, :skel_group, :n, :node, :g, :group].each do |t1|
              [:default_group, :skel_group, :n, :node, :g, :group].each do |t2|
                target1 = t1.to_s.gsub(/_/,'-') + (t1.to_s.include?('_') ? "" : " blah")
                target2 = t2.to_s.gsub(/_/,'-') + (t2.to_s.include?('_') ? "" : " blah")
                it "should only allow 1 target using #{target1} and #{target2} as targets" do
                  lambda {Mrg::Grid::Config::CCP.new.main("#{t1.to_s.length > 1 ? "--" : "-"}#{target1}".split + "#{t2.to_s.length > 1 ? "--" : "-"}#{target2}".split + @ccp_act + @ccp_ent)}.should raise_error
                end
              end
            end

            [:default_group, :skel_group, :n, :node, :g, :group].each do |target|
              ws_target = target.to_s["g"] ? "Group" : "Node"
              name = target.to_s.include?('_') ? "+++#{target.to_s.split('_')[0].upcase}" : target.to_s.upcase
              it "should pass #{target} as #{ws_target}=#{name}" do
                Mrg::Grid::Config::Shell.should_receive(:main).with(@ws_cmd + ["#{ws_target}=#{name}", *@cmd_feat_args])
                Mrg::Grid::Config::CCP.new.main(["#{target.to_s.length > 1 ? "--" : "-"}#{target.to_s.gsub(/_/, '-')}", "#{ws_target.to_s.include?('_') ? nil : name}"] + @ccp_args)
              end

            end

            [:g, :group].each do |target|
              it "should handle #{target} names with commas" do
                name = "name,with,comma"
                Mrg::Grid::Config::Shell.should_receive(:main).with(@ws_cmd + ["Group=#{name}", *@cmd_feat_args])
                Mrg::Grid::Config::CCP.new.main(["#{target.to_s.length > 1 ? "--" : "-"}#{target}", name] + @ccp_args)
              end
            end

            it "should accept \"Internal Default Group\" as a target group name" do
              Mrg::Grid::Config::Shell.should_receive(:main).with(@ws_cmd + ["Group=+++DEFAULT", *@cmd_feat_args])
              Mrg::Grid::Config::CCP.new.main(["-g \"Internal Default Group\""] + @ccp_args)
            end
          end

          describe "for actions" do
            it "should require an action" do
              lambda {Mrg::Grid::Config::CCP.new.main(@ccp_target + @ccp_ent)}.should raise_error
            end

            it "should only allow 1 action" do
              lambda {Mrg::Grid::Config::CCP.new.main(@ccp_target + @ccp_act + @ccp_act + @ccp_ent)}.should raise_error
            end

            [:add, :delete, :edit, :insert, :list].each do |act|
              ws_act = act == :delete ? :remove : act
              it "should convert #{act} into the ccp-#{ws_act} command" do
                Mrg::Grid::Config::Shell.should_receive(:main).with(["ccp-#{ws_act}"] + @ws_target + @cmd_feat_args)
                Mrg::Grid::Config::CCP.new.main(["--#{act}"] + @ccp_target + @ccp_ent)
              end

              it "should convert #{act.to_s[0,1]} into the ccp-#{ws_act} command" do
                Mrg::Grid::Config::Shell.should_receive(:main).with(["ccp-#{ws_act}"] + @ws_target + @cmd_feat_args)
                Mrg::Grid::Config::CCP.new.main(["-#{act.to_s[0,1]}"] + @ccp_target + @ccp_ent)
              end
            end

            [:load, :take, :remove].each do |act|
              cmd = "#{act == :take ? "make" : act}-snapshot"
              it "should call wallaby shell command #{cmd} directly for snapshots" do
                name = "snap"
                Mrg::Grid::Config::Shell.should_receive(:main).with([cmd, name])
                Mrg::Grid::Config::CCP.new.main(["--#{act}-snapshot", name])
              end
            end

            it "should call wallaby shell command activate directly" do
              Mrg::Grid::Config::Shell.should_receive(:main).with(["activate"])
              Mrg::Grid::Config::CCP.new.main(["--activate"])
            end
          end

          describe "for list actions" do
            [:features, :groups, :nodes, :params, :snapshots].each do |lact|
              it "should call ccp-listall for #{lact}" do
                Mrg::Grid::Config::Shell.should_receive(:main).with(["ccp-listall", "#{lact.to_s.chop.gsub(/param/, "parameter").capitalize}"])
                Mrg::Grid::Config::CCP.new.main(["--list-all-#{lact}"])
              end

              it "should not allow action and list-all-#{lact}" do 
                lambda {Mrg::Grid::Config::CCP.new.main(@ccp_target + @ccp_act + ["--list-all-#{lact}"] + @ccp_ent)}.should raise_error
              end
            end
          end

          describe "for entities" do
            before(:each) do
              @conv = {:p=>:Parameter, :params=>:Parameter, :f=>:Feature, :features=>:Feature}
            end

            [:p, :params, :f, :features].each do |ent|
              it "should handle #{ent} names with commas" do
                name = "name,with,comma"
                Mrg::Grid::Config::Shell.should_receive(:main).with(@ws_cmd + @ws_target + ["#{@conv[ent]}=#{name}"])
                Mrg::Grid::Config::CCP.new.main(@ccp_target + @ccp_act + ["#{ent.to_s.length > 1 ? "--" : "-"}#{ent}", "\"#{name}\""])
              end

              it "should separate comma delimited list of entities into multiple args when using #{ent} option" do
                name = self.instance_variables.grep(/@#{ent.to_s[0,1]}/).first
                list = self.instance_variable_get(name)
                Mrg::Grid::Config::Shell.should_receive(:main).with(@ws_cmd + @ws_target + list.split(',').collect {|e| "#{@conv[ent]}=#{e}"})
                Mrg::Grid::Config::CCP.new.main(@ccp_target + @ccp_act + ["#{ent.to_s.length > 1 ? "--" : "-"}#{ent}", list])
              end
            end
          end
        end
      end
    end
  end
end
