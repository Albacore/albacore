require "albacore/albacoretask"

class PLink
  include Albacore::Task
  include Albacore::RunCommand

  attr_reader   :verbose

  attr_accessor :host, 
                :port, 
                :user, 
                :key

  attr_array    :commands

  def initialize()
    @port = 22
    super()
  end

  def execute()
    unless @command
      fail_with_message("plink requires #command")
      return
    end
    
    result = run_command("plink", build_parameters)
    fail_with_message("PLink failed, see the build log for more details") unless result
  end

  def verbose
    @verbose = true
  end
    
  def build_parameters
    p = []
    p << "#{"#{@user}@" if @user}#{@host} -P #{port}"
    p << "-i #{@key}" if @key
    p << "-batch"
    p << "-v" if @verbose
    p << @commands if @commands
    p
  end
end
