require "spec_helper" 

describe NuGetPack do
  subject(:task) do
    task = NuGetPack.new()
    task.extend(SystemPatch)
    task.command = "nuget"
    task.nuspec = "nuspec"
    task.output = "out/package"
    task.base_folder = "bin/Release"
    task.properties = {:foo => "foo", :bar => "bar"}
    task.symbols
    task
  end

  let(:cmd) { task.system_command }

  before :each do
    task.execute
  end
  
  it "should set the command" do 
    cmd.should include("nuget")
  end

  it "should set the subcommand" do 
    cmd.should include("pack")
  end
  
  it "should set the nuspec" do
    cmd.should include("\"nuspec\"")
  end
  
  it "should set the output path" do
    cmd.should include("-OutputDirectory \"out/package\"")
  end
  
  it "should set the base folder path" do
    cmd.should include("-BasePath \"bin/Release\"")
  end
  
  it "should set the properties" do
    cmd.should include("-Properties foo=\"foo\";bar=\"bar\"")
  end
  
  it "should make a symbols package" do
    cmd.should include("-Symbols")
  end
end
