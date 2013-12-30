require "spec_helper"
require "albacore/mstesttestrunner"

describe MSTestTestRunner do
  before :all do
    @cmd = MSTestTestRunner.new()
    @cmd.extend(SystemPatch)
    @cmd.extend(FailPatch)
    @cmd.command = "mstest"
    @cmd.assemblies = ["a.dll", "b.dll"]
    @cmd.tests = ["foo", "bar"]
    @cmd.no_logo
    @cmd.execute
  end

  it "should use the command" do
    @cmd.system_command.should include("mstest")
  end

  it "should hide the startup banner" do
    @cmd.system_command.should include("/nologo")
  end

  it "should test the assemblies" do
    @cmd.system_command.should include("/testcontainer:\"a.dll\" /testcontainer:\"b.dll\"")
  end

  it "should run only the tests" do
    @cmd.system_command.should include("/test:foo /test:bar")
  end
end
