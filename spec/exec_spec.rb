require "spec_helper"
require "albacore/exec"

describe Exec do
  subject(:task) do
    task = Exec.new()
    task.extend(SystemPatch)
    task.command = "whatever"
    task.parameters = ["foo", "bar"]
    task
  end

  let(:cmd) { task.system_command }

  before :each do
    task.execute
  end

  it "should run the command" do
    cmd.should include("whatever")
  end

  it "should use both parameters" do
    cmd.should include("foo bar")
  end
end
