require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'condor_wallaby_tools/cmdline'

module Mrg
  module Grid
    module Config

      describe CmdLineUtils do
        before :each do
          @ss = "Single Space"
          @ms = "Multiple Space Arg"
          @sc = "Single,Comma"
          @mc = "Multiple,Comma,Arg"
          @scws = @sc.gsub(/,/, ', ')
          @mcws = @mc.gsub(/,/, ', ')
          @args = "arg1,arg2,arg3"
        end

        include CmdLineUtils

        it "should parse command line arguments with spaces" do
          parse_option_args("\"#{@ss}\"").should == [@ss]
          parse_option_args("\"#{@ms}\"").should == [@ms]
        end

        it "should parse command line arugments with commas" do
          parse_option_args("\"#{@sc}\"").should == [@sc]
          parse_option_args("\"#{@scws}\"").should == [@scws]
          parse_option_args("\"#{@mc}\"").should == [@mc]
          parse_option_args("\"#{@mcws}\"").should == [@mcws]
        end

        it "should parse multiple command line arugments with spaces and commas" do
          parse_option_args("\"#{@ss}\",\"#{@sc}\"").should == [@ss, @sc]
          parse_option_args("\"#{@ss}\",\"#{@scws}\"").should == [@ss, @scws]
          parse_option_args("\"#{@ms}\",\"#{@mc}\"").should == [@ms, @mc]
          parse_option_args("\"#{@ms}\",\"#{@mcws}\"").should == [@ms, @mcws]
          parse_option_args("\"#{@ms}\",\"#{@mc}\"," + @args).should == [@ms, @mc] + @args.split(',')
        end

        it "should parse multiple command line arguments separated by commas" do
          parse_option_args(@args).should == @args.split(',')
        end
      end
    end
  end
end
