require "spec_helper"

describe NAnt do
  subject(:task) do
    task = NAnt.new()
    task.extend(SystemPatch)
    task.command = "nant"
    task.targets = [:clean, :build]
    task.build_file = "buildfile"
    task.properties = {:foo => "foo", :bar => "bar"}
    task.no_logo
    task
  end

  let(:cmd) { task.system_command }

  before :each do
    task.execute
  end

  it "should use the command" do
    cmd.should include("nant") 
  end

  it "should run the targets" do
    cmd.should include("clean build")
  end

  it "should use the build file" do
    cmd.should include("-buildfile:\"buildfile\"")
  end

  it "should hide the startup banner" do
    cmd.should include("-nologo")
  end

  it "should set the properties" do
    cmd.should include("-D:foo=\"foo\" -D:bar=\"bar\"")
  end
end
