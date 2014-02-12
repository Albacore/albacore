require "albacore/albacoretask"
require "albacore/config/sqlcmdconfig"

class SQLCmd
  TaskName = :sqlcmd

  VERSIONS  = ["110", "100", "90"]
  PLATFORMS = [ENV["PROGRAMFILES"], ENV["PROGRAMFILES(X86)"]].compact

  include Albacore::Task
  include Albacore::RunCommand
  include Configuration::SQLCmd

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
    @command = default_command || "sqlcmd"
    
    super()
    update_attributes(sqlcmd.to_hash)
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
    p << @variables.map { |key, value| "-v #{key}=\"#{value}\"" } if @variables
    p << "-b" if @batch_abort
    p << @scripts.map { |script| "-i \"#{script}\"" } if @scripts
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

  def default_command
    PLATFORMS.product(VERSIONS).map { |env, ver| install_path(env, ver) }.find { |path| File.exist?(path) }
  end

  def install_path(platform, version)
    File.join(platform, "Microsoft SQL Server", version, "tools/binn/sqlcmd.exe")
  end
end
