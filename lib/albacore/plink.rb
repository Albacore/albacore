require "albacore/albacoretask"
require "albacore/config/plinkconfig"

class PLink
  TaskName = :plink
  
  include Albacore::Task
  include Albacore::RunCommand
  include Configuration::PLink

  attr_reader   :verbose

  attr_accessor :host, 
                :port, 
                :user, 
                :key

  attr_array    :commands

  def initialize()
    @port = 22
    
    super()
    update_attributes(plink.to_hash)
  end

  def execute()
    unless @command
      fail_with_message("plink requires #command")
      return
    end
    
    result = run_command("plink", build_parameters)
    fail_with_message("PLink failed, see the build log for more details") unless result
  end

  def build_parameters
    p = []
    p << "#{"#{@user}@" if @user}#{@host} -P #{@port}"
    p << "-i #{@key}" if @key
    p << "-batch"
    p << "-v" if @verbose
    p << @commands if @commands
    p
  end

  def verbose
    @verbose = true
  end    
end
