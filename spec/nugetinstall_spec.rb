require 'spec_helper'
require 'albacore/nugetinstall'

describe NuGetInstall do  
  before :each do
    @nugetinstall = NuGetInstall.new
    @strio = StringIO.new
    @nugetinstall.log_device = @strio
    @nugetinstall.log_level = :diagnostic
  end

  context "when no path to NuGet is specified" do
    it "assumes NuGet is in the path" do
      @nugetinstall.command.should == "NuGet.exe"
    end
  end

  it "generates the correct command-line parameters" do
    @nugetinstall.package = "Hircine"
    @nugetinstall.sources = "source1", "source2"
    @nugetinstall.version = "0.1.1-pre"
    @nugetinstall.no_cache = false
    @nugetinstall.prerelease = true
    @nugetinstall.exclude_version = true
    @nugetinstall.output_directory = "customdir"
    
    params = @nugetinstall.generate_params
    params.should include("install")
    params.should include(@nugetinstall.package)
    params.should include("-Version 0.1.1-pre")
    params.should include("-Source \"source1;source2\"")
    params.should include("-OutputDirectory customdir")
    params.should include("-ExcludeVersion")
    params.should include("-Prerelease")
    params.should_not include("-NoCache")
    
    @nugetinstall.no_cache = true
    params = @nugetinstall.generate_params
    params.should include("-NoCache")
  end

  it "fails if no package is specified" do
  	@nugetinstall.extend(FailPatch)
  	@nugetinstall.generate_params
  	@strio.string.should include('A NuGet package must be specified.')
  end
end