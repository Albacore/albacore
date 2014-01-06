require "spec_helper"

describe NuGetInstall do  
  subject(:task) do
    task = NuGetInstall.new()
    task.extend(SystemPatch)
    task.command = "nuget"
    task.package = "Hircine"
    task.sources = ["source1", "source2"]
    task.version = "0.1.1-pre"
    task.output_directory = "customdir"
    task.no_cache
    task.prerelease
    task.exclude_version
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
    cmd.should include("install")
  end

  it "should use the package" do
    cmd.should include("Hircine")
  end

  it "should set the version" do
    cmd.should include("-Version 0.1.1-pre")
  end
    
  it "should use the sources" do
    cmd.should include("-Source \"source1;source2\"")
  end

  it "should use the output directory" do
    cmd.should include("-OutputDirectory \"customdir\"")
  end

  it "should exclude the version" do
    cmd.should include("-ExcludeVersion")
  end

  it "should be a pre release" do
    cmd.should include("-Prerelease")
  end

  it "should not cache" do
    cmd.should include("-NoCache")
  end
end
