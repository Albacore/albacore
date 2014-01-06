require "spec_helper"

describe PLink do
  subject(:task) do
    task = PLink.new()
    task.extend(SystemPatch)
    task.command = "plink"
    task.host = "host"
    task.port = 443
    task.user = "username"
    task.key = "key"
    task.verbose
    task.commands = ["foo", "bar"]
    task
  end

  let(:cmd) { task.system_command }

  before :each do
    task.execute
  end

  it "should use the command" do
    cmd.should include("plink")
  end

  it "should use the correct connection" do
    cmd.should include("username@host -P 443")
  end

  it "should use the key" do
    cmd.should include("-i key")
  end

  it "should batch the commands" do
    cmd.should include("-batch")
  end

  it "should be verbose" do
    cmd.should include("-v")
  end

  it "should send the remote commands" do
    cmd.should include("foo bar")
  end

  context "when plinking without a user" do
    before :each do
      task.user = nil
    end

    it "should use the correct connection" do
      cmd.should include("host -P 443")
    end
  end
end
