require "spec_helper"

describe NuGetPack do
  subject(:task) do
    task = NuGetPush.new()
    task.extend(SystemPatch)
    task.command = "nuget"
    task.package = "package"
    task.apikey = "apikey"
    task.source = "source"
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
    cmd.should include("push")
  end 
  
  it "should set the package" do 
    cmd.should include("\"package\"")
  end 

  it "should set the apikey" do 
    cmd.should include("apikey")
  end 
  
  it "should set the source" do 
    cmd.should include("-Source source")
  end 
end
