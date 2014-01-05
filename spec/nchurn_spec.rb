require "spec_helper"
require "albacore/nchurn"

describe NChurn do
  subject(:task) do
    task = NChurn.new()
    task.extend(SystemPatch)
    task.command = "nchurn"
    task.input = "input"
    task.output = "output"
    task.from = DateTime.parse("01-01-2001")
    
    # you're only supposed ot use one of these, 
    # but we don't enforce it and this cheating 
    # makes testing easier ;)
    task.churn = 9
    task.churn_percent = 30

    task.top = 10
    task.report_as = :xml
    task.adapter = :git
    task.env_paths = ["c:/bin", "c:/tools"]
    task.include = "foo"
    task.exclude = "bar"
    task
  end

  let(:cmd) { task.system_command }

  before :each do
    task.execute
  end

  it "should use the command" do
    cmd.should include("nchurn")
  end

  it "should use this input" do
    cmd.should include("-i \"input\"")
  end

  it "should output here" do
    cmd.should include("> \"output\"")
  end

  it "should use this date range" do
    cmd.should include("-d \"01-01-2001\"")
  end

  it "should expect this churn" do
    cmd.should include("-c 9")
  end

  it "should expect this churn percent" do
    cmd.should include("-c 0.3")
  end

  it "should return the top records" do
    cmd.should include("-t 10")
  end

  it "should report as" do
    cmd.should include("-r xml")
  end

  it "should expect this repository" do
    cmd.should include("-a git")
  end

  it "should add this env path" do
    cmd.should include("-p \"c:/bin;c:/tools\"")
  end

  it "should include this" do
    cmd.should include("-n \"foo\"")
  end

  it "should exclude this" do
    cmd.should include("-x \"bar\"")
  end
end
