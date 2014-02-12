require "spec_helper"

describe XUnit do
  subject(:task) do
    task = XUnit.new()
    task.extend(SystemPatch)
    task.command = "xunit"
    task.assembly = "a.dll"
    task.results_path = {:html => "output.html"}
    task
  end

  let(:cmd) { task.system_command }

  before :each do
    task.execute
  end

  it "should use the command" do
    cmd.should include("xunit")
  end

  it "should test one assembly" do
    cmd.should include("\"a.dll\"")
  end

  it "should output to an unedited path" do
    cmd.should include("/html \"output.html\"")
  end
end
