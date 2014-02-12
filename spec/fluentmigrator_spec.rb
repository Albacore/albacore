require "spec_helper"

describe FluentMigrator do
  subject(:task) do
    task = FluentMigrator.new()
    task.extend(SystemPatch)
    task.command = "fluentm"
    task.namespace = "namespace"
    task.provider = "provider"
    task.target = "target"
    task.connection = "connection"
    task.out
    task.out_file = "output.txt"
    task.steps = 1
    task.task = "migrate:up"
    task.version = "001"
    task.script_directory = "scripts"
    task.profile = "profile"
    task.timeout = 90
    task.tag = "tag"
    task.verbose
    task.preview
    task
  end

  let(:cmd) { task.system_command }

  before :each do
    task.execute
  end

  it "should run target" do
    cmd.should include("/target=\"target\"")
  end

  it "should use provider" do
    cmd.should include("/provider=provider")
  end

  it "should use connection" do
    cmd.should include("/connection=\"connection\"")
  end  

  it "should include the namespace" do
    cmd.should include("/ns=namespace")
  end

  it "should output to the specified file" do
    cmd.should include("/out")
    cmd.should include("/outfile=\"output.txt\"")
  end 

  it "should step once" do
    cmd.should include("/steps=1")
  end

  it "should run the task" do
    cmd.should include("/task=migrate:up")
  end

  it "should run to version one" do
    cmd.should include("/version=001")
  end

  it "should use the working directory" do
    cmd.should include("/wd=\"scripts\"")
  end

  it "should use profile" do
    cmd.should include("/profile=profile")
  end

  it "should timeout" do
    cmd.should include("/timeout=90")
  end
  
  it "should include tag" do
    cmd.should include("/tag=tag")
  end

  it "should preview" do
    cmd.should include("/preview")
  end
  
  it "should be verbose" do
    cmd.should include("/verbose=true")
  end
end
