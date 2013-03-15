require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

#require 'wallaby/spec_helper'
require 'condor_wallaby/configparser'

module Wallaroo
  module Shell
    describe CommandArgs do

      [TestClass, TestClass2].each do |k1|
        k1.cmd_args.each do |arg1|
          k2 = k1.name.include?("2") ? self.const_get(k1.name.chop) : self.const_get("#{k1.name}2")
          m1 = arg1.to_s.gsub(/-/, '_')
          it "should not add method #{m1} from #{k1.name} to the class" do
            klass = class << k1; self end
            klass.method_defined?(m1).should == false
          end

          it "should add method #{m1} from #{k1.name} to the module" do
            k1.method_defined?(m1).should == true
          end

          it "should add method #{m1} from #{k1.name} as an instance method" do
            k1.instance_methods.include?(m1).should == true
          end

          it "should not add method #{m1} from #{k1.name} as a class method" do
            k1.singleton_methods.include?(m1).should == false
          end

          k2.cmd_args.each do |arg2|
            m2 = arg2.to_s.gsub('-', '_')
            it "should not add #{m2} from #{k2.name} to the class" do
              klass = class << k1; self end
              klass.method_defined?(m2).should == false
            end

            it "should not add #{m2} from #{k2.name} to the module" do
              k1.method_defined?(m2).should == false
            end
          end
        end
      end

      it "should not add arg_list method to the class" do
        klass = class << TestClass; self end
        klass.method_defined?(:arg_list).should == false
      end

      it "should add arg_list method to the module" do
        TestClass.method_defined?(:arg_list).should == true
      end

      it "should set the value of arg_list to the cmd_args from TestClass" do
        TestClass.new.arg_list.should == TestClass.cmd_args
      end

      it "should set the value of arg_list to the cmd_args from TestClass2" do
        TestClass2.new.arg_list.should == TestClass2.cmd_args
      end

      [[:initializer, :init], [:after_option_parsing, :parse_args]].each do |t, f|
        it "should register an #{t} callback with function #{f}" do
          TestClass.callbacks.keys.should include t
          TestClass.callbacks[t].should include f
        end
      end

      describe "#get_env" do
        it "should return the value as a symbol if the variable is defined in the environment" do
          ENV["name"] = "value"
          TestClass.new.get_env("name").should == :value
          ENV.delete("name")
        end
        it "should return nil if the variable is not defined in the environment" do
          TestClass.new.get_env("name").should == nil
        end
      end

      describe "#fdata" do
        it "should return the value if the variable is defined in the file data for a given name" do
          o = TestClass3.new
          o.fdata(:var).should == "value"
        end

        it "should return nil if the given name is not defined in the file data" do
          o = TestClass3.new
          o.config[:name] = "test2"
          o.fdata(:var).should == nil
        end

        it "should return nil if the given name is defined but the variable isn't in the file data" do
          o = TestClass3.new
          o.fdata(:var2).should == nil
        end
      end

      describe "#name" do
        it "should return the name defined in config" do
          TestClass3.new.name.should == TestClass3.new.config[:name]
        end

        it "should return the name defined in environment if config is not defined" do
          o = TestClass.new
          ENV["#{o.env_prefix}_NAME"] = "name"
          o.name.should == "name"
          ENV.delete("#{o.env_prefix}_NAME")
        end

        it "should return nil if name is not defined in config or environment" do
          TestClass.new.name.should == nil
        end

        it "should give precedence to config if config and environment are defined" do
          o = TestClass3.new
          def o.env_prefix; return "TEST"; end
          ENV["#{o.env_prefix}_NAME"] = "FROM_ENV"
          o.name.should == o.config[:name]
          ENV.delete("#{o.env_prefix}_NAME")
        end
      end

      describe "#include" do
        it "should return the name in config" do
          o = TestClass3.new
          o.instance_variable_get(:@fdata)[o.name].delete(:include)
          o.include.should == TestClass3.new.config[:include]
        end

        it "should return the name in file data if it is not present in config" do
          o = TestClass3.new
          o.config.delete(:include)
          o.include.should == o.fdata(:include)
        end

        it "should return the name defined in def_include if not defined elsewhere" do
          o = TestClass3.new
          o.config.delete(:include)
          o.instance_variable_get(:@fdata)[o.name].delete(:include)
          o.include.should == o.def_include
        end

        it "should prefer the value in config over file data" do
          TestClass3.new.include.should == TestClass3.new.config[:include]
          TestClass3.new.include.should_not == TestClass3.new.instance_variable_get(:@fdata)[TestClass3.new.name][:include]
        end
      end

      describe "#read_file" do
        it "should raise an error if the filename doesn't exist" do
          lambda {TestClass3.new.read_file}.should raise_error(ExitStub::ShellError) && exit_with_code(1)
        end

        it "should do nothing if filename option isn't provided" do
          o = TestClass3.new
          o.instance_variable_get(:@options).delete(:infile)
          File.stub!(:read).and_raise(ExitStub::ShellError)
          lambda {o.read_file}.should_not raise_error(ExitStub::ShellError)
        end

        it "should merge data from the file" do
          o = TestClass3.new
          File.stub!(:exist?).and_return(true)
          File.stub!(:read)
          ConfigParser.stub!(:parse).and_return({"feature"=>{:attr1=>"value1", :attr2=>"value2"}})
          o.instance_variable_get(:@fdata)["feature"] = {:base1=>"base val", :attr1=>"base val 2"}
          o.read_file
          data = o.instance_variable_get(:@fdata)
          data.keys.should include "feature"
          data["feature"].keys.should include :attr1
          data["feature"].keys.should include :attr2
          data["feature"].keys.should include :base1
          data["feature"][:attr1].should == "value1"
        end

        it "should read data from the file" do
          o = TestClass3.new
          File.stub!(:exist?).and_return(true)
          File.stub!(:read)
          ConfigParser.stub!(:parse).and_return({:feature=>{:attr1=>"value1", :attr2=>"value2"}})
          o.read_file
          data = o.instance_variable_get(:@fdata)
          data.keys.should include :feature
          data[:feature].keys.should include :attr1
          data[:feature].keys.should include :attr2
        end
      end
    end
  end
end
