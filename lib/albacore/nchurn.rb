require "albacore/albacoretask"

class NChurn
  TaskName = :nchurn

  include Albacore::Task
  include Albacore::RunCommand
  
  attr_accessor :from, 
                :churn, 
                :churn_percent,
                :top, 
                :report_as, 
                :env_path, 
                :adapter, 
                :exclude, 
                :include, 
                :output
    
  def initialize
    super()
    update_attributes(Albacore.configuration.nchurn.to_hash)
  end
  
  def execute
    result = run_command("NChurn", build_parameters)
    fail_with_message("NChurn failed, see the build log for more details.") unless result
  end
  
  def build_parameters
    p = []
    p << "-d #{quotes(@from.strftime("%d-%m-%Y"))}" if @from
    p << "-i #{quotes(@input)}" if @input
    p << "-c #{@churn_percent / 100.0}" if @churn_percent
    p << "-c #{@churn}" if @churn
    p << "-t #{@top}" if @top
    p << "-r #{@report_as}" if @report_as
    p << "-p #{quotes(@env_path)}" if @env_path
    p << "-a #{@adapter}" if @adapter
    p << "-x #{quotes(@exclude)}" if @exclude
    p << "-n #{quotes(@include)}" if @include
    p << "> #{quotes(@output)}" if @output
    p
  end
  
  def churn_precent(p)
    @churn_percent = p
  end

  def input(p)
    @input = p
  end

  def from(p)
    @from = p
  end

  def churn(p)
    @churn = p
  end

  def top(p)
    @top = p
  end

  def report_as(p)
    @report_as = p
  end

  def env_path(p)
    @env_path = p
  end

  def adapter(p)
    @adapter = p
  end

  def exclude(p)
    @exclude = p
  end

  def include(p)
    @include = p
  end

  def output(p)
    @output = p
  end

  private
  def quotes(s)
   "\"#{s}\""
  end
end
