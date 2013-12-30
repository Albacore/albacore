require "spec_helper"
require "albacore/ilmerge"

describe IlMerge do
  before :all do
    @cmd = IlMerge.new()
    @cmd.extend(SystemPatch)
    @cmd.extend(FailPatch)
    @cmd.command = "ilmerge"
    @cmd.output = "output.dll"
    @cmd.target_platform = "net40"
    @cmd.assemblies = ["a.dll", "b.dll"]
    @cmd.execute
  end

  it "should use the command" do
    @cmd.system_command.should include("ilmerge")
  end

  it "should output to the assembly" do
    @cmd.system_command.should include("/out:\"output.dll\"")
  end

  it "should target the correct platform" do
    @cmd.system_command.should include("/targetPlatform:net40")
  end

  it "should use the input assemblies" do
    @cmd.system_command.should include("\"a.dll\" \"b.dll\"")
  end
end
