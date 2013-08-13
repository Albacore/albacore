require 'spec_helper'
require 'albacore/cross_platform_cmd'
require 'albacore/errors/command_not_found_error'

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

[:system, :sh, :shie].each do |method|
  describe Albacore::CrossPlatformCmd.method(:system), "#system" do
    it "should be callable" do
      subject.should respond_to(:call)
    end
    it "doesn't crash everything when called" do
      subject.call("whoami").should_not be_nil
    end
    it "should raise Error for nonexisting command" do
      expect { subject.call("nonexistent", :silent => true) }.to raise_error(Albacore::CommandNotFoundError)
    end
    it "should state that the command failed" do
      begin
        subject.call("nonexistent")
      rescue Albacore::CommandNotFoundError => re
        re.message.should include("Command failed with status (127) - number 127 in particular means that the operating system could not find the executable:\n  nonexistent")
      end
    end
    let(:cwd) { File.dirname(__FILE__) }
    let(:runtime) { "/usr/bin/mono" }
    it "should fail with RuntimeError if status is not zero" do
      begin
        if ::Rake::Win32.windows?
          subject.call("#{cwd}/support/returnstatus/returnstatus.exe", [45])
        else
          subject.call(runtime, %W[#{cwd}/support/returnstatus/returnstatus.exe 45])
        end
        raise "should have thrown"
      rescue RuntimeError => e
        e.message.should include('Command failed')
      end
    end
    # TODO it "should redirect stderr" do ; end
    # TODO it "should return output"
    # TODO: cmd DSL w/ mono_command
  end
end

describe Albacore::CrossPlatformCmd.method(:sh), "#sh" do
  let(:prefix) { 
    folder = File.dirname(__FILE__)
    # TODO: cmd DSL w/ mono_command
    ::Rake::Win32.windows? ? folder : "mono #{folder}"
  }
  it "should output from echo" do
    res = subject.call("#{prefix}/support/echo/echo.exe this is a test")
    res.should eq("this is a test\n")
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
