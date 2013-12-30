require "spec_helper"
require "albacore/aspnetcompiler"
require "albacore/support/platform"

describe AspNetCompiler do
  before :each do
    @cmd = AspNetCompiler.new()
    @cmd.extend(SystemPatch)
    @cmd.extend(FailPatch)
    @cmd.command = "aspnetcompiler"
    @cmd.physical_path = "physical/path"
    @cmd.target_path = "target/path"
    @cmd.clean
    @cmd.debug
    @cmd.force
    @cmd.fixed_names
    @cmd.delay_sign
    @cmd.updateable
    @cmd.no_logo
  end

  describe AspNetCompiler, "when overriding all values" do
    before :each do
      @cmd.virtual_path = "virtual/path"
      @cmd.execute
    end

    it "should use the command" do
      @cmd.system_command.should include("aspnetcompiler")
    end

    it "should use the physical path" do
      @cmd.system_command.should include("-p \"physical/path\"") if Albacore::Support::Platform.linux?
      @cmd.system_command.should include("-p \"physical\\path\"") if !Albacore::Support::Platform.linux?
    end

    it "should use the target path" do
      @cmd.system_command.should include("\"target/path\"") if Albacore::Support::Platform.linux?
      @cmd.system_command.should include("\"target\\path\"") if !Albacore::Support::Platform.linux?
    end

    it "should use default virtual path" do
      @cmd.system_command.should include("-v virtual/path")
    end

    it "should be clean" do 
      @cmd.system_command.should include("-c")
    end

    it "should show no logo" do
      @cmd.system_command.should include("-nologo")
    end

    it "should delay sign" do 
      @cmd.system_command.should include("-delaysign")
    end

    it "should use fixed names" do 
      @cmd.system_command.should include("-fixednames")
    end

    it "should be updateable" do 
      @cmd.system_command.should include("-u")
    end

    it "should force" do 
      @cmd.system_command.should include("-f")
    end

    it "should debug" do 
      @cmd.system_command.should include("-d")
    end
  end

  describe AspNetCompiler, "when relying on defaults" do
    before :each do
      @cmd.execute
    end

    it "should use the default virtual path" do
      @cmd.system_command.should include("-v /")
    end
  end
end
