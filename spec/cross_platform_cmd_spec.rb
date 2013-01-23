require 'albacore/cross_platform_cmd'

describe "expectations on Kernel#system and Rake::Win32#rake_system" do
  subject { ::Rake::Win32.windows? ? Rake::Win32.method(:rake_system) : Kernel.method(:system) }
  let(:res) { subject.call "whoami" }
  it("returns true if the command was successful") { res.should be_true }
end

describe Albacore::CrossPlatformCmd.method(":system"), "#system" do
  it "should be callable" do
    subject.should respond_to(:call)
  end
  it "doesn't crash everything when called" do
    subject.call("whoami").should_not be_nil
  end
end

describe Albacore::CrossPlatformCmd.method(:sh), "#sh" do
  it "should raise Error for nonexisting command" do
    expect { subject.call("nonexistent") }.to raise_error(RuntimeError)
  end
  it "should state that the command failed" do
    begin
      subject.call("nonexistent")
    rescue RuntimeError => re
      re.message.should include("Command failed with status (")
    end
  end
end