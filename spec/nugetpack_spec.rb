require "spec_helper"
require "albacore/nugetpack"

describe NuGetPack do
  before :each do
    @cmd = NuGetPack.new()
    @cmd.extend(SystemPatch)
    @cmd.extend(FailPatch)
    @cmd.command = "nuget"
    @cmd.nuspec = "nuspec"
    @cmd.output = "out/package"
    @cmd.base_folder = "bin/Release"
    @cmd.properties = {:foo => "foo", :bar => "bar"}
    @cmd.symbols
    @cmd.execute
  end
  
  it "should set the command" do 
    @cmd.system_command.should include("nuget")
  end

  it "should set the subcommand" do 
    @cmd.system_command.should include("pack")
  end
  
  it "should set the nuspec" do
    @cmd.system_command.should include("\"nuspec\"")
  end
  
  it "should set the output path" do
    @cmd.system_command.should include("\"out/package\"")
  end
  
  it "should set the base folder path" do
    @cmd.system_command.should include("\"bin/Release\"")
  end
  
  it "should set the properties hash" do
    @cmd.system_command.should include("foo=\"foo\"")
    @cmd.system_command.should include("bar=\"bar\"")
  end
  
  it "should set symbols switch" do
    @cmd.system_command.should include("-Symbols")
  end
end
