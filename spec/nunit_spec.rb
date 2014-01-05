require "spec_helper"
require "albacore/nunit"

describe NUnit do
  subject(:task) do
    task = NUnit.new()
    task.extend(SystemPatch)
    task.command = "nunit"
    task.assemblies = ["a.dll", "b.dll"]
    task.results_path = "results.xml"
    task.no_logo
    task
  end

  let(:cmd) { task.system_command }

  before :each do
    task.execute
  end

  it "should use the command" do
    cmd.should include("nunit")
  end

  it "should test the assemblies" do
    cmd.should include("\"a.dll\" \"b.dll\"")
  end

  it "should write to this output file" do
    cmd.should include("/xml=\"results.xml\"")
  end

  it "should hide the startup banner" do
    cmd.should include("/nologo")
  end
end
