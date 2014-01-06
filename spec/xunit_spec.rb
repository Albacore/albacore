require "spec_helper"

describe XUnit do
  subject(:task) do
    task = XUnit.new()
    task.extend(SystemPatch)
    task.command = "xunit"
    task.output_path = {:html => "output.html"}
    task
  end

  let(:cmd) { task.system_command }

  context "when testing a single assembly" do
    before :each do
      task.assemblies = ["a.dll"]
      task.execute
    end

    it "should use the command" do
      cmd.should include("xunit")
    end

    it "should test one assembly" do
      cmd.should include("\"a.dll\"")
    end

    it "should output to an unedited path" do
      cmd.should include("/html \"output.html\"")
    end
  end

  context "when testing multiple assemblies" do
    before :each do
      task.assemblies = ["a.dll", "b.dll"]
      task.execute
    end
    
    it "should test both assemblies" do
      cmd.should include("\"b.dll\"")
    end
    
    it "should output to the indexed path" do
      cmd.should include("\"./output_2.html\"")
    end
  end

  context "when continuing on error" do
    before :each do
      task.force_failure
      task.assemblies = ["a.dll"]
      task.continue_on_error
    end

    it "should not fail" do
      expect { task.execute }.to_not raise_error
    end
  end
end
