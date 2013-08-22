require 'spec_helper'
require 'albacore/cross_platform_cmd'
require 'albacore/errors/command_not_found_error'
require 'albacore/errors/command_failed_error'

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
  describe Albacore::CrossPlatformCmd.method(method), "##{method}" do
    describe 'its positive modes' do
      it "should be callable" do
        subject.should respond_to(:call)
      end
      it "doesn't crash everything when called" do
        subject.call("whoami").should_not be_nil
      end
    end
    unless method == :shie
      describe 'its failure modes / exit codes' do
        it "should raise Error for nonexisting command" do
          expect { subject.call("nonexistent", :silent => true) }.to raise_error(Albacore::CommandNotFoundError)
        end
        it "should state that the command failed" do
          expect { subject.call("nonexistent") }.to raise_error(
            Albacore::CommandNotFoundError,
            /Command failed with status \(127\) - number 127 in particular means that the operating system could not find the executable:\n  nonexistent/)
        end
        let(:cwd) { File.dirname(__FILE__) }
        let(:runtime) { "/usr/bin/mono" }
        it "should fail with RuntimeError if status is not zero" do
          expect { 
            if ::Rake::Win32.windows?
              subject.call("#{cwd}/support/returnstatus/returnstatus.exe", [45])
            else
              subject.call(runtime, %W[#{cwd}/support/returnstatus/returnstatus.exe 45])
            end
          }.to raise_error(Albacore::CommandFailedError, /Command failed/)
        end
      end
    end
    describe 'its output' do
      let :prefix do 
        folder = File.dirname(__FILE__)
        ::Rake::Win32.windows? ? folder : "mono #{folder}"
      end
      it "should output from echo" do
        res = subject.call("#{prefix}/support/echo/echo.exe this is a test")
        res.should eq("this is a test\n")
      end
    end
  end
end
