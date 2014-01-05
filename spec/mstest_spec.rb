require "spec_helper"
require "albacore/mstest"

describe MSTest do
  subject(:task) do
    task = MSTest.new()
    task.extend(SystemPatch)
    task.command = "mstest"
    task.assemblies = ["a.dll", "b.dll"]
    task.tests = ["foo", "bar"]
    task.no_logo
    task
  end

  let(:cmd) { task.system_command }

  before :each do
    task.execute
  end

  it "should use the command" do
    cmd.should include("mstest")
  end

  it "should hide the startup banner" do
    cmd.should include("/nologo")
  end

  it "should test the assemblies" do
    cmd.should include("/testcontainer:\"a.dll\" /testcontainer:\"b.dll\"")
  end

  it "should run only the tests" do
    cmd.should include("/test:foo /test:bar")
  end
end
