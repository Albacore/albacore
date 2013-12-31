require "albacore/albacoretask"
require "albacore/config/nchurnconfig"

class NChurn
  TaskName = :nchurn

  include Albacore::Task
  include Albacore::RunCommand
  include Configuration::NChurn
  
  attr_accessor :from, 
                :churn, 
                :churn_percent,
                :top, 
                :report_as, 
                :adapter, 
                :exclude, 
                :include, 
                :input,
                :output

  attr_array    :env_paths 
    
  def initialize
    super()
    update_attributes(nchurn.to_hash)
  end
  
  def execute
    result = run_command("NChurn", build_parameters)
    fail_with_message("NChurn failed, see the build log for more details.") unless result
  end
  
  def build_parameters
    p = []
    p << "-d \"#{@from.strftime("%d-%m-%Y")}\"" if @from
    p << "-i \"#{@input}\"" if @input
    p << "-c #{@churn_percent / 100.0}" if @churn_percent
    p << "-c #{@churn}" if @churn
    p << "-t #{@top}" if @top
    p << "-r #{@report_as}" if @report_as
    p << "-p \"#{@env_paths.join(";")}\"" if @env_paths
    p << "-a #{@adapter}" if @adapter
    p << "-x \"#{@exclude}\"" if @exclude
    p << "-n \"#{@include}\"" if @include
    p << "> \"#{@output}\"" if @output
    p
  end
end
