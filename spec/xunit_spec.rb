require 'spec_helper'
require 'albacore/xunittestrunner'

describe XUnitTestRunner, "when using basic definitions" do
  before :each do
    @cmd = XUnitTestRunner.new
    @cmd.extend(SystemPatch)
    @cmd.extend(FailPatch)
    @cmd.command = "xunit"
    @cmd.output_path = {:html => "output.html"}
  end

  describe XUnitTestRunner, "when testing a single assembly" do
    before :each do
      @cmd.assemblies = ["a.dll"]
      @cmd.execute
    end
    
    it "should output to the unedited path" do
      @cmd.system_command.should include("/html \"output.html\"")
    end
    
    it "should use the only assembly" do
      @cmd.system_command.should include("\"a.dll\"")
    end
    
    it "should use the given command" do
      @cmd.system_command.should include("xunit")
    end
  end

  describe XUnitTestRunner, "when testing multiple assemblies" do
    before :each do
      @cmd.assemblies = ["a.dll", "b.dll"]
      @cmd.execute
    end
    
    it "should send both assembly commands" do
      @cmd.system_command.should include("\"b.dll\"")
    end
    
    it "should append an index to the output path" do
      @cmd.system_command.should include("\"./output_2.html\"")
    end
  end

  describe XUnitTestRunner, "when continuing on error" do
    before :each do
      @cmd.continue_on_error
      @cmd.disable_system = true
      @cmd.assemblies = ["a.dll"]
      @cmd.execute
    end

    it "should not fail" do
      $task_failed.should be_false
    end
  end
end
