require 'spec_helper'
require 'albacore/specflowreport'

describe SpecFlowReport, "when defining a basic specflow report task" do
  before :each do
    @cmd = SpecFlowReport.new()
    @cmd.extend(SystemPatch)
    @cmd.extend(FailPatch)
    @cmd.command = "specflow"
    @cmd.report = :nunitexecutionreport
    @cmd.project = "myproject.csproj"
    @cmd.execute
  end

  it "should use the given command" do
    @cmd.system_command.should include("specflow")
  end 

  it "should use the given report" do
    @cmd.system_command.should include("nunitexecutionreport")
  end 

  it "should use the given project" do
    @cmd.system_command.should include("\"myproject.csproj\"")
  end 
end