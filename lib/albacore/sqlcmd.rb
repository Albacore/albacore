require "albacore/albacoretask"

class SQLCmd
  TaskName = :sqlcmd

  include Albacore::Task
  include Albacore::RunCommand

  VERSIONS  = ["110", "100", "90"]
  PLATFORMS = [ENV["PROGRAMFILES"], ENV["PROGRAMFILES(X86)"]]

  attr_reader   :trusted_connection,
                :ignore_variables,
                :batch_abort
  
  attr_accessor :server, 
                :database, 
                :username, 
                :password, 
                :severity

  attr_array    :scripts

  attr_hash     :variables
  
  def initialize
    @command = VERSIONS.product(PLATFORMS).
      map  { |ver, env| File.join(env, "Microsoft SQL Server", ver, "tools", "binn", "sqlcmd.exe") if env }.
      find { |path| File.exist?(path) }.
      gsub("\\", "/")
    
    super()
    update_attributes(Albacore.configuration.sqlcmd.to_hash)
  end
  
  def execute
    unless @command
      fail_with_message("sqlcmd requires #command")
      return
    end
    
    result = run_command("sqlcmd", build_parameters)
    fail_with_message("SQLCMD failed, see the build log for more details.") unless result
  end
  
  def build_parameters
    p = []
    p << "-S \"#{@server}\"" if @server
    p << "-d \"#{@database}\"" if @database
    p << "-E" if @trusted_connection
    p << "-U \"#{@username}\" -P \"#{@password}\"" if (@username && @password)
    p << @variables.map { |k,v| "-v #{k}=\"#{v}\"" } if @variables
    p << "-b" if @batch_abort
    p << @scripts.map{ |s| "-i \"#{s}\"" } if @scripts
    p << "-V #{@severity}" if @severity
    p << "-x" if @ignore_variables
    p
  end

  def trusted_connection
    @trusted_connection = true
  end
  
  def ignore_variables
    @ignore_variables = true
  end
  
  def batch_abort
    @batch_abort = true
  end
end
