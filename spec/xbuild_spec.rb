require "spec_helper"

describe XBuild do
  subject(:task) do
    task = XBuild.new()
    task.extend(SystemPatch)
    task.command = "xbuild"
    task.solution = "solution"
    task.verbosity = "minimal"
    task.targets = [:clean, :build]
    task.properties = {:foo => "foo", :bar => "bar"}
    task
  end

  let(:cmd) { task.system_command }

  before :each do
    task.execute
  end
  
  it "should use the command" do 
    cmd.should include("xbuild")
  end
  
  it "should build the solution" do
    cmd.should include("\"solution\"")
  end
  
  it "should be verbose" do 
    cmd.should include("/verbosity:minimal")
  end
  
  it "should use the targets" do 
    cmd.should include("/target:clean;build")
  end
  
  it "should set the properties" do
    cmd.should include("/p:foo=\"foo\" /p:bar=\"bar\"")
  end
end
