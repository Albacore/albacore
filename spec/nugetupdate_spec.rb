require "spec_helper"
require "albacore/nugetupdate"

describe NuGetUpdate do  
  subject(:task) do
    task = NuGetUpdate.new()
    task.extend(SystemPatch)
    task.command = "nuget"
    task.input_file = "TestSolution.sln"
    task.source = ["source1", "source2"]
    task.id = ["id1", "id2"]
    task.repository_path = "repopath"
    task.safe
    task
  end

  let(:cmd) { task.system_command }

  before :each do
    task.execute
  end

  it "should use the command" do
    cmd.should include("nuget")
  end
  
  it "should use the subcommand" do
    cmd.should include("update")
  end
  
  it "should use the input file" do
    cmd.should include("\"TestSolution.sln\"")
  end
  
  it "should use the sources" do
    cmd.should include("-Source \"source1;source2\"")
  end
  
  it "should use the ids" do
    cmd.should include("-Id \"id1;id2\"")
  end
  
  it "should use the repo path" do
    cmd.should include("-RepositoryPath repopath")
  end
  
  it "should be safe" do
    cmd.should include("-Safe")
  end
end
