require "spec_helper"
require "albacore/docu"

describe Docu, "when defining a basic docu task" do  
  subject(:task) do
    task = Docu.new()
    task.extend(SystemPatch)
    task.output_path = "whatever"
    task.assemblies = ["a.dll", "b.dll"]
    task.xml_files = ["a.xml", "b.xml"]
    task
  end

  let(:cmd) { task.system_command }

  before :each do
    task.execute
  end

  it "should dress up the output path" do
    cmd.should include("--output=\"whatever\"")
  end

  it "should list the assemblies" do 
    cmd.should include("\"a.dll\" \"b.dll\"")
  end

  it "should list the xml files" do 
    cmd.should include("\"a.xml\" \"b.xml\"")
  end
 end
 
