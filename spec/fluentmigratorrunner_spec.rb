require "spec_helper"
require "albacore/fluentmigratorrunner"

describe FluentMigratorRunner do
  before :all do
    @cmd = FluentMigratorRunner.new()
    @cmd.extend(SystemPatch)
    @cmd.extend(FailPatch)
    @cmd.command = "fluentm"
    @cmd.namespace = "namespace"
    @cmd.provider = "provider"
    @cmd.target = "target"
    @cmd.connection = "connection"
    @cmd.output
    @cmd.output_filename = "output.txt"
    @cmd.steps = 1
    @cmd.task = "migrate:up"
    @cmd.version = "001"
    @cmd.script_directory = "scripts"
    @cmd.profile = "profile"
    @cmd.timeout = 90
    @cmd.tag = "tag"
    @cmd.verbose
    @cmd.preview
    @cmd.execute
  end

  it "should run target" do
    @cmd.system_command.should include("/target=\"target\"")
  end

  it "should use provider" do
    @cmd.system_command.should include("/provider=provider")
  end

  it "should use connection" do
    @cmd.system_command.should include("/connection=\"connection\"")
  end  

  it "should include the namespace" do
    @cmd.system_command.should include("/ns=namespace")
  end

  it "should output to the specified file" do
    @cmd.system_command.should include("/out")
    @cmd.system_command.should include("/outfile=\"output.txt\"")
  end 

  it "should step once" do
    @cmd.system_command.should include("/steps=1")
  end

  it "should run the task" do
    @cmd.system_command.should include("/task=migrate:up")
  end

  it "should run to version one" do
    @cmd.system_command.should include("/version=001")
  end

  it "should use the working directory" do
    @cmd.system_command.should include("/wd=\"scripts\"")
  end

  it "should use profile" do
    @cmd.system_command.should include("/profile=profile")
  end

  it "should timeout" do
    @cmd.system_command.should include("/timeout=90")
  end
  
  it "should include tag" do
    @cmd.system_command.should include("/tag=tag")
  end

  it "should preview" do
    @cmd.system_command.should include("/preview")
  end
  
  it "should be verbose" do
    @cmd.system_command.should include("/verbose=true")
  end
end
