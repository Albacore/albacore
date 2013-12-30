require "spec_helper"
require "albacore/csc"

describe CSC do
  before :all do
    @cmd = CSC.new()
    @cmd.extend(SystemPatch)
    @cmd.extend(FailPatch)
    @cmd.command = "csc"
    @cmd.compile = ["File1.cs", "File2.cs"]
    @cmd.references = ["foo.dll"]
    @cmd.resources = ["foo.resx"]
    @cmd.define = [:symbol1, :symbol2]
    @cmd.target = :library
    @cmd.output = "output.dll"
    @cmd.doc = "docfile.xml"
    @cmd.main = "Program"
    @cmd.key_file = "keyfile"
    @cmd.key_container = "keycontainer"
    @cmd.optimize
    @cmd.debug :full 
    @cmd.delay_sign
    @cmd.no_logo
    @cmd.execute
  end

  it "should use the command" do
    @cmd.system_command.should include("csc")
  end

  it "should compile two files" do
    @cmd.system_command.should include("\"File1.cs\"")
    @cmd.system_command.should include("\"File2.cs\"")
  end

  it "should output the library" do
    @cmd.system_command.should include("/out:\"output.dll\"")
  end

  it "should reference the library" do
    @cmd.system_command.should include("/reference:\"foo.dll\"")
  end

  it "should include the resource" do
    @cmd.system_command.should include("/resource:\"foo.resx\"")
  end

  it "should optimize" do
    @cmd.system_command.should include("/optimize")
  end

  it "should delay sign" do
    @cmd.system_command.should include("/delaysign+")
  end

  it "should not display a logo" do
    @cmd.system_command.should include("/nologo")
  end

  it "should debug at the full level" do
    @cmd.system_command.should include("/debug:full")
  end

  it "should write documentation" do
    @cmd.system_command.should include("/doc:\"docfile.xml\"")
  end

  it "should define the symbols" do
    @cmd.system_command.should include("/define:symbol1;symbol2")
  end

	it "should have a main entry" do
		@cmd.system_command.should include("/main:Program")
	end

  it "should have a key file and container" do
    @cmd.system_command.should include("/keyfile:\"keyfile\"")
    @cmd.system_command.should include("/keycontainer:keycontainer")
  end
end
