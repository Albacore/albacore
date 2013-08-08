require 'spec_helper'
require 'albacore/cross_platform_cmd'

# ignore, because it's an integration test that I can't control the output of
#describe "expectations on Kernel#system and Rake::Win32#rake_system" do
#  subject { ::Rake::Win32.windows? ? Rake::Win32.method(:rake_system) : Kernel.method(:system) }
#  let(:res) { subject.call "whoami" }
#  it("returns true if the command was successful") { res.should be_true }
#end

describe Albacore::CrossPlatformCmd.method(:which), "what happens when calling #which" do
  it "should be callable" do
    subject.should respond_to(:call)
  end
  it "should return a non-null path" do
    subject.call("ruby").should_not be_empty
  end
  it "should return nil if nothing was found" do
    subject.call("notlikelyonsystem").should be_nil
  end
end

describe Albacore::CrossPlatformCmd.method(:system), "#system" do
  it "should be callable" do
    subject.should respond_to(:call)
  end
  it "doesn't crash everything when called" do
    subject.call("whoami").should_not be_nil
  end
end

describe Albacore::CrossPlatformCmd.method(:sh), "#sh" do

  let(:prefix) { 
    folder = File.dirname(__FILE__)
    ::Rake::Win32.windows? ? folder : "mono #{folder}"
  }

  it "should raise Error for nonexisting command" do
    expect { subject.call("nonexistent", :silent => true) }.to raise_error(RuntimeError)
  end
  it "should state that the command failed" do
    begin
      subject.call("nonexistent")
    rescue RuntimeError => re
      re.message.should include("Command failed with status (127)")
    end
  end
  it "should output from echo" do
    res = subject.call("#{prefix}/support/echo/echo.exe this is a test")
    res.should eq(["this is a test \n"])
  end
  it "should fail with RuntimeError if status is not zero" do
    begin
      subject.call("#{prefix}/support/returnstatus/returnstatus.exe 45")
      raise "should have thrown"
    rescue
      # pass!
    end
  end
end

describe Albacore::CrossPlatformCmd.method(:shie), "#shie" do
  let(:fun) { Albacore::CrossPlatformCmd.method(:shie) }
  context "invoking non existing binary" do
    subject { "nonexisting" }
    let(:ret) { fun.call(subject) }
    it "should be indexable" do
      ret.should respond_to(:"[]")
    end
    it "should return failure first: res[0] = false" do
      ret[0].should be_false
    end
    it "should return something with an exit status" do
      ret[1].exitstatus.should be(127)
    end
  end
  context "invoking existing binary" do
    subject { "ruby --version" }
    let(:ret) { fun.call(subject) }
    it "should return successful" do
      ret[0].should be_true
    end
    it "should exit with zero as exit status" do
      ret[1].exitstatus.should eq(0)
    end
    it "should return something with a pid in user mode" do
			if ::Rake::Win32.windows?
			  ret[1].pid.should > 0
			else
        ret[1].pid.should > 1000
		  end
    end
  end
end
