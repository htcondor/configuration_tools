require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'wallaby/spec_helper'

module Mrg
  module Grid
    module Config
      module Shell
        describe CCPOps do
          include BaseDBFixture

          before(:each) do
            @tester = CCPOpsTester.new
            setup_rhubarb
            @store = Store.new
            @tester.store = @store
            @name = "nodename"

            hide_output
          end

          after(:each) do
            show_output
            teardown_rhubarb
          end

          describe "#params_as_array" do
            it "should create array of key=value from hash with values" do
              list = @tester.params_as_array({"a"=>1, "b"=>"hello"})
              list.should include "a=1"
              list.should include "b=hello"
            end

            it "should create array of keys from hash with no values" do
              list = @tester.params_as_array({"a"=>nil, "b"=>nil})
              list.should include "a"
              list.should include "b"
            end
          end

          describe "#entities_needed" do
            [:schedds, :qmf, :neither].each do |opt|
              it "should return #{opt == :neither ? "false" : "true"} if options contains #{opt}" do
                @tester.options = {opt=>true}
                @tester.entities_needed.should == (opt == :neither)
              end
            end
          end

          describe "#parse_args" do
            it "should raise exception if no target specified" do
              lambda {@tester.parse_args("")}.should raise_error(ShellCommandFailure)
              lambda {@tester.parse_args("Feature=test")}.should raise_error(ShellCommandFailure)
            end

            it "should raise exception if no entities specified" do
              lambda {@tester.parse_args("Node=test")}.should raise_error(ShellCommandFailure)
            end

            [:Group, :Node].each do |ent|
              it "should accept #{ent} as a target" do
                CCPOpsTester.opname = "test-add"
                name = "Name"
                add_entity(name, ent)
                @tester.parse_args("#{ent}=#{name}", "Feature=test")
                @tester.target[ent].should == "#{name}"
              end

              it "should raise an exception if the name of the target #{ent} does not exist in the store" do
                lambda {@tester.parse_args("#{ent}=bah", "Feature=test")}.should raise_error(ShellCommandFailure)
              end
            end

            [:Parameter, :Feature].each do |ent|
              it "should raise an exception if the target is not a valid type" do
                lambda {@tester.parse_args("#{ent}=bah", "Feature=test")}.should raise_error(ShellCommandFailure)
              end

              [:add, :remove].each do |act|
                it "should create a set of #{ent} from #{ent}=VALUE arguments for action #{act}" do
                  verify_cmd_params(ent, act)
                end
              end

              [:upcase, :downcase, :capitalize].each do |method|
                it "should accept #{ent} names that are #{method}d" do
                  verify_cmd_params(ent.to_s.send(method), :add)
                end
              end
            end
          end

          describe "#save_snapshot_cmds" do
            it "should generate a snapshot command with the name provided" do
              name = "testsnap"
              cmd = @tester.save_snapshot_cmds(name)
              cmd[0].should == Mrg::Grid::Config::Shell::MakeSnapshot
              cmd[1].should == [name]
            end

            it "should generate a snapshot command with an empty string if no name given" do
              cmd = @tester.save_snapshot_cmds
              cmd[0].should == Mrg::Grid::Config::Shell::MakeSnapshot
              cmd[1].should == [""]
            end
          end

          describe "#activate_cmds" do
            it "should generate an activate cmd" do
              cmd = @tester.activate_cmds
              cmd[0].should == Mrg::Grid::Config::Shell::Activate
              cmd[1].should == []
            end
          end

          describe "#target_obj" do
            name = "Test"
            [:Node, :Group].each do |ent|
              it "should return the #{ent == :Node ? "identity group" : "group"} object if the target is a #{ent}" do
                add_entity(name, ent)
                @tester.target = {ent=>name}
                obj = @tester.target_obj
                obj.class.should == Mrg::Grid::Config::Group
                obj.is_identity_group.should == (ent == :Node ? true : false)
              end
            end
          end

          describe "#hashify" do
            it "should convert a list into a hash with nil values" do
              list = ["a", "b", "c"]
              hashed = @tester.hashify(list)
              list.each do |v|
                hashed.keys.should include v
                hashed[v].should == nil
              end
            end
          end

          describe "#get_param_values" do
            it "should prompt for values for parameters being added" do
              params = ["p1", "p2", "p3"]
              params.each do |p|
                @tester.add_parameters[p] = nil
              end
              STDIN.should_receive(:gets).and_return("test1", "4", "1.2")
              @tester.get_param_values
              params.each do |p|
                @tester.add_parameters[p].should_not == nil
              end
            end
          end

          describe "#config_node_schedulers" do
            it "should not do anything if the schedd option wasn't provided" do
              @tester.config_node_schedulers
              @tester.add_parameters.should == {}
              @tester.remove_parameters.should == {}
            end

            it "should add schedd params to remove list for remove command" do
              @tester.options[:schedds] = nil
              CCPOpsTester.opname = "test-remove"
              params = @tester.add_parameters
              @tester.remove_parameters.keys.should_not include "SCHEDD_NAME"
              @tester.remove_parameters.keys.should_not include "SCHEDD_HOST"
              @tester.config_node_schedulers
              @tester.remove_parameters.keys.should include "SCHEDD_NAME"
              @tester.remove_parameters.keys.should include "SCHEDD_HOST"
              @tester.add_parameters.should == params
            end

            [:add, :edit].each do |cmd|
              [true, false].each do |ha|
                schedd_name = "schedd" + (ha ? "@" : "")
                it "should add schedd params to add and remove lists for #{ha ? "HA" : "non-HA"} schedd with #{cmd} command" do

                  STDIN.should_receive(:gets).and_return(schedd_name, (ha ? "y" : "n"))
                  @tester.options[:schedds] = nil
                  CCPOpsTester.opname = "test-#{cmd}"
                  @tester.add_parameters.keys.should_not include "SCHEDD_NAME"
                  @tester.add_parameters.keys.should_not include "SCHEDD_HOST"
                  @tester.remove_parameters.keys.should_not include "SCHEDD_NAME"
                  @tester.remove_parameters.keys.should_not include "SCHEDD_HOST"
                  @tester.config_node_schedulers
                  @tester.add_parameters[ha ? "SCHEDD_NAME" : "SCHEDD_HOST"].should == schedd_name
                  @tester.remove_parameters.keys.should include ha ? "SCHEDD_HOST" : "SCHEDD_NAME"
                end
              end
            end
          end

          describe "#config_qmf_broker" do
            it "should not do anything if the qmf option wasn't provided" do
              @tester.config_qmf_broker
              @tester.add_parameters.should == {}
              @tester.remove_parameters.should == {}
            end

            it "should add QMF broker params to remove list for remove command" do
              @tester.options[:qmf] = nil
              CCPOpsTester.opname = "test-remove"
              params = @tester.add_parameters
              @tester.remove_parameters.keys.should_not include "QMF_BROKER_HOST"
              @tester.remove_parameters.keys.should_not include "QMF_BROKER_PORT"
              @tester.config_qmf_broker
              @tester.remove_parameters.keys.should include "QMF_BROKER_HOST"
              @tester.remove_parameters.keys.should include "QMF_BROKER_PORT"
              @tester.add_parameters.should == params
            end

            [:add, :edit].each do |cmd|
              [["1"], ["1.1", "a", "port", "-4.1", "1"]].each do |ports|
                host = "host123"
                it "should add QMF broker params to add list with #{cmd} command and ensure port is valid" do

                  STDIN.should_receive(:gets).and_return(host, *ports)
                  @tester.options[:qmf] = nil
                  CCPOpsTester.opname = "test-#{cmd}"
                  params = @tester.remove_parameters
                  @tester.add_parameters.keys.should_not include "QMF_BROKER_HOST"
                  @tester.add_parameters.keys.should_not include "QMF_BROKER_PORT"
                  @tester.config_qmf_broker
                  @tester.remove_parameters.should == params
                  @tester.add_parameters["QMF_BROKER_HOST"].should == host
                  @tester.add_parameters["QMF_BROKER_PORT"].should == ports.last
                end
              end
            end
          end

          describe "#check_add_params_needed" do
            before(:each) do
              reconstitute_db
              @node = @store.addNode(@name)
              @route = ["route1", "start=true", "m1.small", "public.key", "private.key", "access.key", "secret.key", "rsa.key", "s3bucket", "sqsqueue", "ami"]
              @tester.target = {:Node=>@name}

              # EC2 Enhanced params
              @ec2e_feature = "EC2Enhanced"
              @ec2e_set_route = "NEED_SET_EC2E_ROUTES"
              @ec2e_routes = "JOB_ROUTER_ENTRIES"

              # VM Universe params
              @vmu_feature = "VMUniverse"
              @vmu_type = "VM_TYPE"
              @xen_bloader = "XEN_BOOTLOADER"
              @vmu_network = "VM_NETWORKING"
              @vmu_nettype = "VM_NETWORKING_TYPE"
              @vmu_def_nettype = "VM_NETWORKING_DEFAULT_TYPE"
              @vmu_bridge_int = "VM_NETWORKING_BRIDGE_INTERFACE"
            end

            # EC2 Enhanced tests
            it "should prompt for EC2 Enhanced routes if feature is being added" do
              @tester.add_features.push(@ec2e_feature)
              STDIN.should_receive(:gets).and_return("y", *@route + ["n"])

              @tester.add_parameters.keys.should_not include @ec2e_routes
              @tester.add_parameters.keys.should_not include @ec2e_set_route
              @tester.check_add_params_needed
              @tester.add_parameters.keys.should include @ec2e_routes
              @tester.add_parameters.keys.should include @ec2e_set_route
              @tester.add_parameters[@ec2e_set_route].should == "FALSE"
            end

            it "should not prompt for EC2 Enhanced routes if the feature is on the node and routes are set" do
              @node.identity_group.modifyFeatures("ADD", [@ec2e_feature], {})
              @node.identity_group.modifyParams("ADD", {@ec2e_set_route=>"FALSE"}, {})
              STDIN.should_not_receive(:gets)
              @tester.add_features.push("ExecuteNode")
              @tester.check_add_params_needed
            end

            it "should prompt for EC2 Enhanced routes if the feature is on the node but no routes are set" do
              @node.identity_group.modifyFeatures("ADD", [@ec2e_feature], {})
              @node.identity_group.modifyParams("ADD", {@ec2e_set_route=>"TRUE"}, {})
              STDIN.should_receive(:gets).and_return("y", *@route + ["n"])
              @tester.add_features.push("ExecuteNode")
              @tester.check_add_params_needed
            end

            [true, false].each do |set|
              it "should #{not set ? "not" : nil} prompt for EC2 Enhanced routes if route param is set to \"#{set.to_s.upcase}\" from the command line" do
                @tester.add_parameters[@ec2e_set_route] = "#{set.to_s.upcase}"
                STDIN.should_receive(:gets).and_return("y", *@route + ["n"]) if set
                STDIN.should_not_receive(:gets) if not set
                @tester.check_add_params_needed
                @tester.add_parameters.keys.should include @ec2e_routes if set
                @tester.add_parameters.keys.should_not include @ec2e_routes if not set
              end
            end

            # VMUniverse tests
            [:xen, :kvm].each do |vm_type|
              [:nat, :bridge, :both].each do |network_type|
                input = [vm_type.to_s, "y", network_type.to_s]
                input.push("br0") if network_type != :nat
                input.push("bridge") if network_type == :both
                it "should configure the VM Universe with VM type #{vm_type} with #{network_type} enabled" do
                  @tester.add_features.push(@vmu_feature)
                  STDIN.should_receive(:gets).and_return(*input)
                  @tester.check_add_params_needed
                  @tester.add_parameters[@vmu_type].should == vm_type.to_s
                  @tester.add_parameters.keys.should include @xen_bloader if vm_type == :xen
                  @tester.remove_parameters.keys.should_not include @xen_bloader if vm_type == :xen
                  @tester.add_parameters.keys.should_not include @xen_bloader if vm_type != :xen
                  @tester.remove_parameters.keys.should include @xen_bloader if vm_type != :xen
                  @tester.add_parameters[@vmu_network].should == "TRUE"
                  @tester.add_parameters[@vmu_nettype].should == (network_type == :both ? "nat, bridge" : network_type.to_s)
                  @tester.add_parameters.keys.should include @vmu_def_nettype if network_type == :both
                  @tester.add_parameters.keys.should_not include @vmu_def_nettype if network_type != :both
                  @tester.remove_parameters.keys.should include @vmu_def_nettype if network_type != :both
                  @tester.remove_parameters.keys.should_not include @vmu_def_nettype if network_type == :both
                  @tester.add_parameters.keys.should include @vmu_bridge_int if network_type != :nat
                end

                it "should keep prompting for networking type until #{network_type} is entered" do
                  @tester.add_features.push(@vmu_feature)
                  STDIN.should_receive(:gets).and_return("invalid", "1", "-2.1", *input)
                  @tester.check_add_params_needed
                end

              end

              [:nat, :bridge].each do |network_type|
                input = [vm_type.to_s, "y", "both", "invalid", "1", "-2.1", network_type.to_s]
                it "should keep prompting for a default networking type until #{network_type} is entered" do
                  @tester.add_features.push(@vmu_feature)
                  STDIN.should_receive(:gets).and_return(*input)
                  @tester.check_add_params_needed
                end
              end

              it "should not prompt for networking parameters if VM networking is disabled with VM type #{vm_type}" do
                @tester.add_features.push(@vmu_feature)
                STDIN.should_receive(:gets).and_return(vm_type.to_s, "n")
                @tester.check_add_params_needed
                @tester.add_parameters[@vmu_network].should == "FALSE"
                @tester.remove_parameters.keys.should include @vmu_nettype
                @tester.remove_parameters.keys.should include @vmu_def_nettype
                @tester.remove_parameters.keys.should include @vmu_bridge_int
              end
            end

            [:y, :n].each do |set|
              it "should prompt for must change params #{set == :y ? "and" : "but not"} values when a feature is added #{set == :y ? "and" : "but"} values are#{set == :n ? " not" : ""} opted to be set at add time" do
                @tester.add_features.push("Master")
                value = "localhost"
                param = "CONDOR_HOST"
                input = [set.to_s]
                input += [value] if set == :y
                STDIN.should_receive(:gets).and_return(*input)
                @tester.check_add_params_needed
                if set == :y
                  @tester.add_parameters.keys.should include param
                  @tester.add_parameters[param].should == value
                else
                  @tester.add_parameters.keys.should_not include param
                end
              end
            end

            [:y, :n].each do |ans|
              it "should prompt to use the default value#{ans == :n ? " and discard the value if it is empty" : ""}" do
                param = "CONDOR_HOST"
                @tester.add_features.push("Master")
                STDIN.should_receive(:gets).and_return("y", "", ans.to_s)
                @tester.check_add_params_needed
                if ans == :n
                  @tester.add_parameters.keys.should include param
                  @tester.add_parameters[param].should == ""
                else
                  @tester.add_parameters.keys.should_not include param
                end
              end
            end

            it "should prompt for a mustchange parameter already set on an entity if the only feature setting the parameter on the entity is the one being added" do
              @node.identity_group.modifyParams("ADD", {"CONDOR_HOST"=>"localhost"}, {})
              @tester.add_features.push("Master")
              STDIN.should_receive(:gets).and_return("n")
              @tester.check_add_params_needed
            end

            it "should not prompt for a mustchange parameter if a different feature then the one being added already set the parameter on the entity" do
              @node.identity_group.modifyFeatures("ADD", ["HACentralManager"], {})
	      @node.identity_group.modifyParams("ADD", {"CONDOR_HOST"=>"localhost", "HAD_LIST"=>"none", "REPLICATION_LIST"=>"none"}, {})
              @tester.add_features.push("Master")
              STDIN.should_not_receive(:gets)
              @tester.check_add_params_needed
            end

            it "should not prompt for a mustchange parameter if the parameter is set on the command line" do
              @tester.add_features.push("Master")
              @tester.add_parameters["CONDOR_HOST"] = "localhost"
              STDIN.should_not_receive(:gets)
              @tester.check_add_params_needed
            end
          end

          describe "#check_remove_params_needed" do
            before(:each) do
              reconstitute_db
              @tester.target = {:Node=>@name}
            end

            it "should remove a mustchange parameter if the associated feature is removed" do
              param = "CONDOR_HOST"
              @tester.remove_features.push("Master")
              @tester.check_remove_params_needed
              @tester.remove_parameters.should include param
            end

            it "should not remove a mustchange parameter if another feature requires it" do
              param = "CONDOR_HOST"
              @node = @store.addNode(@name)
              @node.identity_group.modifyFeatures("ADD", ["Master", "HACentralManager"], {})
              @node.identity_group.modifyParams("ADD", {param=>"localhost"}, {})
              @tester.remove_features.push("HACentralManager")
              @tester.check_remove_params_needed
              @tester.remove_parameters.should_not include param
            end

            ["VMUniverse", "EC2Enhanced"].each do |feat|
              it "should remove all user set #{feat} params if the feature is removed" do
                @tester.remove_features.push(feat)
                @tester.check_remove_params_needed
                @tester.send("#{feat.downcase}_params").each do |p|
                  @tester.remove_parameters.keys.should include p
                end
              end
            end
          end

          describe "#get_unique_mustchange_params" do
            before(:each) do
              reconstitute_db
              @tester.target = {:Node=>@name}
              @node = @store.addNode(@name)
            end

            it "should return the list of mustchange parameters on a single feature that need values" do
              @tester.get_unique_mustchange_params(["Master"]).should == ["CONDOR_HOST"]
            end

            it "should return the list of mustchange parameters on multiple features that need values" do
              list = @tester.get_unique_mustchange_params(["Master", "NodeAccess"])
              list.should include "CONDOR_HOST"
              list.should include "ALLOW_READ"
              list.should include "ALLOW_WRITE"
            end

            it "should not return a mustchange parameter if it is set by another feature on the entity" do
              @node.identity_group.modifyFeatures("ADD", ["HACentralManager"], {})
              @tester.get_unique_mustchange_params(["Master"]).should_not include "CONDOR_HOST"
            end

            it "should return a mustchange parameter if it is already set on an entity, but only by the feature" do
              @node.identity_group.modifyFeatures("ADD", ["Master"], {})
              @node.identity_group.modifyParams("ADD", {"CONDOR_HOST"=>"localhost"}, {})
              @tester.get_unique_mustchange_params(["Master"]).should include "CONDOR_HOST"
            end
          end

        end
      end
    end
  end
end
