require "spec_helper"

describe CSC do
  subject(:task) do
    task = CSC.new()
    task.extend(SystemPatch)
    task.command = "csc"
    task.compile = ["File1.cs", "File2.cs"]
    task.references = ["foo.dll"]
    task.resources = ["foo.resx"]
    task.define = [:symbol1, :symbol2]
    task.target = :library
    task.output = "output.dll"
    task.doc = "docfile.xml"
    task.main = "Program"
    task.key_file = "keyfile"
    task.key_container = "keycontainer"
    task.optimize
    task.debug :full 
    task.delay_sign
    task.no_logo
    task
  end

  let(:cmd) { task.system_command }

  before :each do
    task.execute
  end

  it "should use the command" do
    cmd.should include("csc")
  end

  it "should compile two files" do
    cmd.should include("\"File1.cs\" \"File2.cs\"")
  end

  it "should output the library" do
    cmd.should include("/out:\"output.dll\"")
  end

  it "should reference the library" do
    cmd.should include("/reference:\"foo.dll\"")
  end

  it "should include the resource" do
    cmd.should include("/resource:\"foo.resx\"")
  end

  it "should optimize" do
    cmd.should include("/optimize")
  end

  it "should delay sign" do
    cmd.should include("/delaysign+")
  end

  it "should not display a logo" do
    cmd.should include("/nologo")
  end

  it "should debug at the full level" do
    cmd.should include("/debug:full")
  end

  it "should write documentation" do
    cmd.should include("/doc:\"docfile.xml\"")
  end

  it "should define the symbols" do
    cmd.should include("/define:symbol1;symbol2")
  end

	it "should have a main entry" do
		cmd.should include("/main:Program")
	end

  it "should have a key file" do
    cmd.should include("/keyfile:\"keyfile\"")
  end

  it "should have a key container" do
    cmd.should include("/keycontainer:keycontainer")
  end
end
