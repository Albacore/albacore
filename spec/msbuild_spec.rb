require 'spec_helper'
require 'albacore/msbuild'
require 'albacore/config/msbuildconfig'
require 'msbuildtestdata'

shared_context "prepping msbuild" do
  before :all do
    @testdata = MSBuildTestData.new
    @msbuild = @testdata.msbuild
    @strio = StringIO.new
    @msbuild.log_device = @strio
    @msbuild.log_level = :diagnostic
    @msbuild.properties :platform => 'Any CPU'
 end
end

describe MSBuild, "when building a solution with verbose logging turned on" do  
  include_context "prepping msbuild"
  
  before :all do
    @msbuild.solution = @testdata.solution_path
    @strio = StringIO.new
    @msbuild.log_device = @strio
    @msbuild.log_level = :verbose
    @msbuild.execute
    
    @log_data = @strio.string
  end

  it "should log the msbuild command line being called" do
    com = @log_data.downcase().should include("Executing MSBuild: \"C:/Windows/Microsoft.NET/Framework/v4.0.30319/MSBuild.exe\"".downcase())
  end
end

describe MSBuild, "when building with no solution specified" do
  include_context "prepping msbuild"

  before :all do
    @msbuild.extend(FailPatch)
    @msbuild.execute
    @log_data = @strio.string
  end
  
  it "should log an error message saying the output file is required" do
    @log_data.should include("solution cannot be nil")
  end
end

describe MSBuild, "when an msbuild path is not specified" do
  before :all do
    @testdata = MSBuildTestData.new
    @msbuild = @testdata.msbuild
  end
  
  it "should default to the .net framework v4" do
    @msbuild.command.downcase().should == @testdata.msbuild_path.downcase()
  end
end

describe MSBuild, "when an msbuild path is specified" do
  before :all do
    @testdata = MSBuildTestData.new
    @msbuild = @testdata.msbuild "Some Path"
  end
  
  it "should use the specified path for the msbuild exe" do
    @msbuild.command.should == "Some Path"
  end  
end

describe MSBuild, "when msbuild is configured to use a specific .net version" do
  before :all do
    Albacore.configure do |config|
      config.msbuild.use :net35
    end
    @testdata = MSBuildTestData.new
    @msbuild = @testdata.msbuild
 end

  it "should use the configured version" do
   win_dir = ENV['windir'] || ENV['WINDIR'] || "C:/Windows"
   @msbuild.command.should == File.join(win_dir.dup, 'Microsoft.NET', 'Framework', 'v3.5', 'MSBuild.exe')
  end
end

describe MSBuild, "when msbuild is configured to use a specific .net version, and overriding for a specific instance" do
  before :all do
    Albacore.configure do |config|
      config.msbuild.use :net35
    end
    @testdata = MSBuildTestData.new
    @msbuild = @testdata.msbuild
    @msbuild.use :net40
 end

  it "should use the override version" do
   win_dir = ENV['windir'] || ENV['WINDIR'] || "C:/Windows"
   @msbuild.command.should == File.join(win_dir.dup, 'Microsoft.NET', 'Framework', 'v4.0.30319', 'MSBuild.exe')
  end
end

describe MSBuild, "when building a visual studio solution" do
  include_context "prepping msbuild"

  before :all do
    @msbuild.solution = @testdata.solution_path
    @msbuild.execute
  end
  
  it "should output the solution's binaries" do
    File.exist?(@testdata.output_path).should == true
  end
end

describe MSBuild, "when building a visual studio solution with a single target" do
  include_context "prepping msbuild"

  before :all do
    @msbuild.solution = @testdata.solution_path
    @msbuild.targets :Rebuild
    @msbuild.execute
  end
  
  it "should output the solution's binaries" do
    File.exist?(@testdata.output_path).should == true
  end
end

describe MSBuild, "when building a visual studio solution for a specified configuration" do
  before :all do
    @testdata= MSBuildTestData.new("Release")
    @msbuild = @testdata.msbuild

    @msbuild.properties :configuration => :Release, :platform => 'Any CPU'
    @msbuild.solution = @testdata.solution_path
    @msbuild.execute
  end
  
  it "should build with the specified configuration as a property" do
    @msbuild.system_command.should include("/p:configuration=\"Release\"")
  end
  
  it "should output the solution's binaries according to the specified configuration" do
    File.exist?(@testdata.output_path).should be_true
  end
end

describe MSBuild, "when specifying targets to build" do  
  include_context "prepping msbuild"

  before :all do
    @msbuild.targets :Clean, :Build
    @msbuild.solution = @testdata.solution_path
    @msbuild.execute
  end

  it "should build the targets" do
    @msbuild.system_command.should include("/target:Clean;Build")
  end

end

describe MSBuild, "when building a solution with a specific msbuild verbosity" do
  include_context "prepping msbuild"

  before :all do
    @msbuild.verbosity = "normal"
    @msbuild.solution = @testdata.solution_path
    @msbuild.execute
  end

  it "should call msbuild with the specified verbosity" do
    @msbuild.system_command.should include("/verbosity:normal")
  end
end

describe MSBuild, "when specifying multiple configuration properties" do  
  include_context "prepping msbuild"

  before :all do
    File.delete(@testdata.output_path) if File.exist?(@testdata.output_path)
    
    @msbuild.targets :Clean, :Build
    @msbuild.properties :configuration => :Debug, :DebugSymbols => true, :platform => 'Any CPU'
    @msbuild.solution = @testdata.solution_path
    @msbuild.execute
  end

  it "should specify the first property" do
    @msbuild.system_command.should include("/p:configuration=\"Debug\"")
  end
  
  it "should specifiy the second property" do
    @msbuild.system_command.should include("/p:DebugSymbols=\"true\"")
  end
  
  it "should output the solution's binaries" do
    File.exist?(@testdata.output_path).should == true
  end
end

describe MSBuild, "when specifying a loggermodule" do  
  include_context "prepping msbuild"
  
  before :all do
    @msbuild.solution = @testdata.solution_path
    @msbuild.loggermodule = "FileLogger,Microsoft.Build.Engine;logfile=MyLog.log"
    @msbuild.execute
    
    @log_data = @strio.string
  end

  it "should log the msbuild logger being used" do
    puts @msbuild.system_command
    @msbuild.system_command.should include("/logger:FileLogger,Microsoft.Build.Engine;logfile=MyLog.log")
  end
end

describe MSBuild, "when specifying nologo" do
  include_context "prepping msbuild"

  before :all do
    @msbuild.nologo
    @msbuild.solution = @testdata.solution_path
    @msbuild.execute
  end

  it "should call msbuild with nologo option" do
    @msbuild.system_command.should include("/nologo")
  end
end

describe MSBuild, "when specifying max cpu count" do
  include_context "prepping msbuild"

  before :all do
    @msbuild.max_cpu_count = 2
    @msbuild.solution = @testdata.solution_path
    @msbuild.execute
  end

  it "should call msbuild with maxcpucount option set" do
    @msbuild.system_command.should include("/maxcpucount:2")
  end
end

describe MSBuild, "when including a TrueClass switch" do
  include_context "prepping msbuild"

  before :all do
    @msbuild.other_switches :noconsolelogger => true
    @msbuild.solution = @testdata.solution_path
    @msbuild.execute
  end

  it 'should call msbuild with the noconsolelogger switch' do
    @msbuild.system_command.should include('/noconsolelogger')
  end
end

describe MSBuild, "when including a true symbol switch" do
  include_context "prepping msbuild"

  before :all do
    @msbuild.other_switches :noconsolelogger => :true
    @msbuild.solution = @testdata.solution_path
    @msbuild.execute
  end

  it 'should call msbuild with the noconsolelogger switch' do
    @msbuild.system_command.should include('/noconsolelogger')
  end
end

describe MSBuild, "when including a switch with value" do
  include_context "prepping msbuild"

  before :all do
    @msbuild.other_switches :toolsVersion => 3.5
    @msbuild.solution = @testdata.solution_path
    @msbuild.execute
  end

  it 'should call msbuild with the noconsolelogger switch' do
    @msbuild.system_command.should include("/toolsVersion:\"3.5\"")
  end
end
