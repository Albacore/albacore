require "spec_helper"
require "albacore/nant"

describe NAnt do
  before :all do
    @cmd = NAnt.new()
    @cmd.extend(SystemPatch)
    @cmd.extend(FailPatch)
    @cmd.command = "nant"
    @cmd.targets = [:clean, :build]
    @cmd.build_file = "buildfile"
    @cmd.properties = {:foo => "foo", :bar => "bar"}
    @cmd.no_logo
    @cmd.execute
  end

  it "should use the command" do
    @cmd.system_command.should include("nant") 
  end

  it "should run the targets" do
    @cmd.system_command.should include("clean build")
  end

  it "should use the build file" do
    @cmd.system_command.should include("-buildfile:\"buildfile\"")
  end

  it "should hide the startup banner" do
    @cmd.system_command.should include("-nologo")
  end

  it "should set the properties" do
    @cmd.system_command.should include("-D:foo=\"foo\" -D:bar=\"bar\"")
  end
end
