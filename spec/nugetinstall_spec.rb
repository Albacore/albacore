require 'spec_helper'
require 'albacore/nugetinstall'

describe NuGetInstall do  
  before :each do
    @cmd = NuGetInstall.new()
    @cmd.extend(SystemPatch)
    @cmd.extend(FailPatch)
    @cmd.command = "nuget"
    @cmd.package = "Hircine"
    @cmd.sources = ["source1", "source2"]
    @cmd.version = "0.1.1-pre"
    @cmd.output_directory = "customdir"
    @cmd.no_cache
    @cmd.prerelease
    @cmd.exclude_version
    @cmd.execute
  end

  it "should use the command" do
    @cmd.system_command.should include("nuget")
  end

  it "should use the subcommand" do
    @cmd.system_command.should include("install")
  end

  it "should use the package" do
    @cmd.system_command.should include("Hircine")
  end

  it "should set the version" do
    @cmd.system_command.should include("0.1.1-pre")
  end
    
  it "should use the sources" do
    @cmd.system_command.should include("\"source1;source2\"")
  end

  it "should use the output directory" do
    @cmd.system_command.should include("customdir")
  end

  it "should exclude the version" do
    @cmd.system_command.should include("-ExcludeVersion")
  end

  it "should be a pre release" do
    @cmd.system_command.should include("-Prerelease")
  end

  it "should not cache" do
    @cmd.system_command.should include("-NoCache")
  end
end