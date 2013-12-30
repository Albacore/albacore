require "spec_helper"
require "albacore/nchurn"

describe NChurn do
  before :all do
    @cmd = NChurn.new()
    @cmd.extend(SystemPatch)
    @cmd.extend(FailPatch)
    @cmd.command = "nchurn"
    @cmd.input = "input"
    @cmd.output = "output"
    @cmd.from = DateTime.parse("01-01-2001")
    
    # you're only supposed ot use one of these, 
    # but we don't enforce it and this cheating 
    # makes testing easier ;)
    @cmd.churn = 9
    @cmd.churn_percent = 30

    @cmd.top = 10
    @cmd.report_as = :xml
    @cmd.adapter = :git
    @cmd.env_paths = ["c:/bin", "c:/tools"]
    @cmd.include = "foo"
    @cmd.exclude = "bar"
    @cmd.execute
  end

  it "should use the command" do
    @cmd.system_command.should include("nchurn")
  end

  it "should use this input" do
    @cmd.system_command.should include("-i \"input\"")
  end

  it "should output here" do
    @cmd.system_command.should include("> \"output\"")
  end

  it "should use this date range" do
    @cmd.system_command.should include("-d \"01-01-2001\"")
  end

  it "should expect this churn" do
    @cmd.system_command.should include("-c 9")
  end

  it "should expect this churn percent" do
    @cmd.system_command.should include("-c 0.3")
  end

  it "should return the top records" do
    @cmd.system_command.should include("-t 10")
  end

  it "should report as" do
    @cmd.system_command.should include("-r xml")
  end

  it "should expect this repository" do
    @cmd.system_command.should include("-a git")
  end

  it "should add this env path" do
    @cmd.system_command.should include("-p \"c:/bin;c:/tools\"")
  end

  it "should include this" do
    @cmd.system_command.should include("-n \"foo\"")
  end

  it "should exclude this" do
    @cmd.system_command.should include("-x \"bar\"")
  end
end
