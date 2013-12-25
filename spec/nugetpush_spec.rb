require "spec_helper"
require "albacore/nugetpush"

describe NuGetPack do
  before :each do
    @cmd = NuGetPush.new()
    @cmd.extend(SystemPatch)
    @cmd.extend(FailPatch)
    @cmd.command = "nuget"
    @cmd.package = "package"
    @cmd.apikey = "apikey"
    @cmd.source = "source"
    @cmd.execute
  end
  
  it "should set the command" do 
    @cmd.system_command.should include("nuget")
  end

  it "should set the subcommand" do 
    @cmd.system_command.should include("push")
  end 
  
  it "should set the package" do 
    @cmd.system_command.should include("\"package\"")
  end 

  it "should set the apikey" do 
    @cmd.system_command.should include("apikey")
  end 
  
  it "should set the source" do 
    @cmd.system_command.should include("source")
  end 
end
