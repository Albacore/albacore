require "spec_helper"
require "albacore/msbuild"

describe MSBuild do
  subject(:task) do
    task = MSBuild.new()
    task.extend(SystemPatch)
    task.command = "msbuild"
    task.solution = "solution"
    task.targets = [:clean, :build]
    task.properties = {:foo => "foo", :bar => "bar"}
    task.verbosity = :minimal
    task.logger_module = "loggermodule"
    task.other_switches = {:baz => "baz"}
    task.no_logo
    task
  end

  let(:cmd) { task.system_command }

  before :each do
    task.execute
  end

  it "should use the command" do
    cmd.should include("msbuild")
  end

  it "should build the solution" do 
    cmd.should include("\"solution\"")
  end

  it "should use the targets" do
    cmd.should include("/target:\"clean;build\"")
  end

  it "should set the properties" do
    cmd.should include("/property:foo=\"foo\" /property:bar=\"bar\"")
  end

  it "should set the other switches" do
    cmd.should include("/baz:\"baz\"")
  end

  it "should be verbose" do
    cmd.should include("/verbosity:minimal")
  end

  it "should hide the startup banner" do
    cmd.should include("/nologo")
  end

  it "should log to the module" do
    cmd.should include("/logger:\"loggermodule\"")
  end
end
