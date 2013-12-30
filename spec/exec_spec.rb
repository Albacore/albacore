require "spec_helper"
require "albacore/exec"

describe Exec do
  before :all do
    @cmd = Exec.new()
    @cmd.extend(SystemPatch)
    @cmd.extend(FailPatch)
    @cmd.command = "whatever"
    @cmd.parameters = ["foo", "bar"]
    @cmd.execute
  end

  it "should run the command" do
    @cmd.system_command.should include("whatever")
  end

  it "should use both parameters" do
    @cmd.system_command.should include("foo bar")
  end
end
