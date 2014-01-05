require "spec_helper"
require "albacore/sqlcmd"

describe SQLCmd do
  subject(:task) do
    task = SQLCmd.new
    task.extend(SystemPatch)
    task.command = "sqlcmd"
    task.server = "server"
    task.database = "database"
    task.username = "user"
    task.password = "password"
    task.severity = 1
    task.scripts = ["a.sql", "b.sql"]
    task.variables = {:foo => "foo", :bar => "bar"}
    task.batch_abort
    task.ignore_variables
    task.trusted_connection
    task
  end

  let(:cmd) { task.system_command }

  before :each do
    task.execute
  end

  it "should use the command" do
    cmd.should include("sqlcmd")
  end
  
  it "should use the server" do
    cmd.should include("-S \"server\"")
  end
  
  it "should use the database" do
    cmd.should include("-d \"database\"")
  end

  it "should set batch abort" do
    cmd.should include("-b")
  end

  it "should run the scripts" do
    cmd.should include("-i \"a.sql\" -i \"b.sql\"")
  end
  
  it "should set the variables" do
    cmd.should include("-v foo=\"foo\" -v bar=\"bar\"")
  end

  it "should set the username and password" do
    cmd.should include("-U \"user\" -P \"password\"")
  end
  
  it "should be severe" do
    cmd.should include("-V 1")
  end
  
  it "should ignore variables" do 
    cmd.should include("-x")
  end
  
  it "should use a trusted connection" do 
    cmd.should include("-E")
  end
end
