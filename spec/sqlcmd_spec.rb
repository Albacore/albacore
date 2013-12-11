require 'spec_helper'
require 'albacore/sqlcmd'

describe SQLCmd, "when running a script the easy way" do
  before :all do
    @cmd = SQLCmd.new
    @cmd.extend(SystemPatch)
    @cmd.log_level = :verbose
    @cmd.disable_system = true    
    @cmd.server = "server"
    @cmd.database = "database"
    @cmd.scripts = ["a.sql", "b.sql", "c.sql"]
    @cmd.username = "user"
    @cmd.password = "password"
    @cmd.variables :foo => "foo", :bar => "bar"
    @cmd.severity = 1
    @cmd.batch_abort
    @cmd.ignore_variables
    @cmd.trusted_connection
    @cmd.execute
  end

  it "should find the location of the sqlcmd exe for the user" do
    @cmd.system_command.downcase.should include("sqlcmd.exe")
  end
  
  it "should specify the server" do
    @cmd.system_command.should include("-S \"server\"")
  end
  
  it "should specify the database" do
    @cmd.system_command.should include("-d \"database\"")
  end

  it "should include the -b option" do
    @cmd.system_command.should include("-b")
  end

  it "should specify the first script file" do
    @cmd.system_command.should include("-i \"a.sql\"")
  end

  it "should specify the second script file" do
    @cmd.system_command.should include("-i \"b.sql\"")
  end
  
  it "should specify the third script file" do
    @cmd.system_command.should include("-i \"c.sql\"")
  end
  
  it "should supply the variables to sqlcmd" do
    @cmd.system_command.should include("-v foo=\"foo\"")
    @cmd.system_command.should include("-v bar=\"bar\"")
  end

  it "should specify the username" do
    @cmd.system_command.should include("-U \"user\"")
  end
  
  it "should specify the password" do
    @cmd.system_command.should include("-P \"password\"")
  end
  
  it "should have severity set to correct value" do
    @cmd.system_command.should include("-V 1")
  end
  
  it "should ignore variables" do 
    @cmd.system_command.should include("-x")
  end
  
  it "should use a trusted connection" do 
    @cmd.system_command.should include("-E")
  end
end
