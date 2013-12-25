require "spec_helper"
require "albacore/nugetupdate"

describe NuGetUpdate do  
  before :each do
    @cmd = NuGetUpdate.new()
    @cmd.extend(SystemPatch)
    @cmd.extend(FailPatch)
    @cmd.command = "nuget"
    @cmd.input_file = "TestSolution.sln"
    @cmd.source = ["source1", "source2"]
    @cmd.id = ["id1", "id2"]
    @cmd.repository_path = "repopath"
    @cmd.safe
    @cmd.execute
  end

  it "should use the command" do
    @cmd.system_command.should include("nuget")
  end
  
  it "should use the subcommand" do
    @cmd.system_command.should include("update")
  end
  
  it "should use the input file" do
    @cmd.system_command.should include("\"TestSolution.sln\"")
  end
  
  it "should use the sources" do
    @cmd.system_command.should include("\"source1;source2\"")
  end
  
  it "should use the ids" do
    @cmd.system_command.should include("\"id1;id2\"")
  end
  
  it "should use the repo path" do
    @cmd.system_command.should include("repopath")
  end
  
  it "should be safe" do
    @cmd.system_command.should include("-Safe")
  end
end