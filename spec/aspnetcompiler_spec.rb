require "spec_helper"

describe AspNetCompiler do
  subject(:task) do
    task = AspNetCompiler.new()
    task.extend(SystemPatch)
    task.command = "aspnetcompiler"
    task.physical_path = "physical/path"
    task.target_path = "target/path"
    task.clean
    task.debug
    task.force
    task.fixed_names
    task.delay_sign
    task.updateable
    task.no_logo
    task
  end

  let(:cmd) { task.system_command }

  context "when overriding all values" do
    before :each do
      task.virtual_path = "virtual/path"
      task.execute
    end

    it "should use the command" do
      cmd.should include("aspnetcompiler")
    end

    it "should use the physical path" do
      cmd.should include("-p \"physical/path\"") if Albacore::Support::Platform.linux?
      cmd.should include("-p \"physical\\path\"") if !Albacore::Support::Platform.linux?
    end

    it "should use the target path" do
      cmd.should include("\"target/path\"") if Albacore::Support::Platform.linux?
      cmd.should include("\"target\\path\"") if !Albacore::Support::Platform.linux?
    end

    it "should use default virtual path" do
      cmd.should include("-v virtual/path")
    end

    it "should be clean" do 
      cmd.should include("-c")
    end

    it "should show no logo" do
      cmd.should include("-nologo")
    end

    it "should delay sign" do 
      cmd.should include("-delaysign")
    end

    it "should use fixed names" do 
      cmd.should include("-fixednames")
    end

    it "should be updateable" do 
      cmd.should include("-u")
    end

    it "should force" do 
      cmd.should include("-f")
    end

    it "should debug" do 
      cmd.should include("-d")
    end
  end

  context "when relying on defaults" do
    before :each do
      task.execute
    end

    it "should use the default virtual path" do
      cmd.should include("-v /")
    end
  end
end
