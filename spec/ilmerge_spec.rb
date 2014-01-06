require "spec_helper"

describe ILMerge do
  subject(:task) do
    task = ILMerge.new()
    task.extend(SystemPatch)
    task.command = "ilmerge"
    task.output = "output.dll"
    task.target_platform = "net40"
    task.assemblies = ["a.dll", "b.dll"]
    task
  end

  let(:cmd) { task.system_command }

  before :each do
    task.execute
  end

  it "should use the command" do
    cmd.should include("ilmerge")
  end

  it "should output to the assembly" do
    cmd.should include("/out:\"output.dll\"")
  end

  it "should target the correct platform" do
    cmd.should include("/targetPlatform:net40")
  end

  it "should use the input assemblies" do
    cmd.should include("\"a.dll\" \"b.dll\"")
  end
end
