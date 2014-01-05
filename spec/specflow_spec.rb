require "spec_helper"
require "albacore/specflow"

describe SpecFlow do
  subject(:task) do
    task = SpecFlow.new()
    task.extend(SystemPatch)
    task.command = "specflow"
    task.report = :nunitexecutionreport
    task.project = "myproject.csproj"
    task
  end

  let(:cmd) { task.system_command }

  before :each do
    task.execute
  end

  it "should use the command" do
    cmd.should include("specflow")
  end 

  it "should use the given report" do
    cmd.should include("nunitexecutionreport")
  end 

  it "should use the given project" do
    cmd.should include("\"myproject.csproj\"")
  end 
end
