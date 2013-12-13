require 'spec_helper'
require 'albacore/xbuild'

describe XBuild, "when executing a basic xbuild command" do
  before :each do
    @cmd = XBuild.new
    @cmd.extend(SystemPatch)
    @cmd.extend(FailPatch)
    @cmd.command = "xbuild"
    @cmd.solution = "solution"
    @cmd.verbosity = "verbose"
    @cmd.targets = [:clean, :build]
    @cmd.properties = {:foo => "foo", :bar => "bar"}
    @cmd.execute
  end
  
  it "should use the given command" do 
    @cmd.system_command.should include("xbuild")
  end
  
  it "should build the solution" do
    @cmd.system_command.should include("\"solution\"")
  end
  
  it "should be verbose" do 
    @cmd.system_command.should include("/verbosity:verbose")
  end
  
  it "should target clean and build" do 
    @cmd.system_command.should include("/target:clean;build")
  end
  
  it "should have the foo and bar props" do
    @cmd.system_command.should include("/p:foo=\"foo\"")
    @cmd.system_command.should include("/p:bar=\"bar\"")
  end
end
