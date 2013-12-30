require "spec_helper"
require "albacore/mspectestrunner"

describe MSpecTestRunner do
  before :all do
    @cmd = MSpecTestRunner.new()
    @cmd.extend(SystemPatch)
    @cmd.extend(FailPatch)
    @cmd.command = "mspec"
    @cmd.assemblies = ["a.dll", "b.dll"]
    @cmd.html_output = "output.html"
    @cmd.execute
  end

  it "should use the command" do
    @cmd.system_command.should include("mspec")
  end
  
  it "should have two assemblies" do
    @cmd.system_command.should include("\"a.dll\" \"b.dll\"")
  end
  
  it "should have an html switch and path" do
    @cmd.system_command.should include("--html \"output.html\"")
  end
end
