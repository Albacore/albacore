require "spec_helper"

describe NDepend do
  subject(:task) do
    task = NDepend.new()
    task.extend(SystemPatch)
    task.command = "ndepend"
    task.project_file = "projectfile"
    task
  end

  let(:cmd) { task.system_command }

  before :each do
    task.execute
  end

  it "should use the command" do
    cmd.should include("ndepend")
  end

  # Bad! How do I stub File.expand_path? Or use the albacore.rb file?
  it "should use the project file" do
    cmd.should include("\"#{File.expand_path("projectfile")}\"")
  end
end
