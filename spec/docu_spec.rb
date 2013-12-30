require "spec_helper"
require "albacore/docu"

describe Docu, "when defining a basic docu task" do  
  before :all do
    @cmd = Docu.new
    @cmd.extend(SystemPatch)
    @cmd.extend(FailPatch)
    @cmd.output_path = "whatever"
    @cmd.assemblies = ["a.dll", "b.dll"]
    @cmd.xml_files = ["a.xml", "b.xml"]
    @cmd.execute
  end

  it "should dress up the output path" do
    @cmd.system_command.should include("--output=\"whatever\"")
  end

  it "should list the assemblies" do 
    @cmd.system_command.should include("\"a.dll\"")
    @cmd.system_command.should include("\"b.dll\"")
  end

  it "should list the xml files" do 
    @cmd.system_command.should include("\"a.xml\"")
    @cmd.system_command.should include("\"b.xml\"")
  end
 end
 