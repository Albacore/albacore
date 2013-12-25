require "albacore/albacoretask"
require "albacore/ncoverreports"
require "albacore/config/ncoverreportconfig"

class NCoverReport
  TaskName = :ncoverreport

  include Albacore::Task
  include Albacore::RunCommand
  
  attr_array :coverage_files, 
             :reports, 
             :required_coverage, 
             :filters
  
  def initialize
    super()
    update_attributes(Albacore.configuration.ncoverreport.to_hash)
  end
  
  def execute
    unless @command
      fail_with_message("ncoverreport requires #command")
      return
    end
    
    result = run_command("ncoverreport", build_parameters)
    fail_with_message("NCover Report failed, see the build log for more details.") unless result
  end
  
  def build_parameters
    p = []
    p << @coverage_files.map{ |f| "\"#{f}\"" } if @coverage_files
    p << @reports.map { |r| "//or #{r.get_report_options}" } if @reports
    p << @required_coverage.map{ |c| "//mc #{c.get_coverage_options}" } if @required_coverage
    p << @filters.map{ |f| "//cf #{f.get_filter_options}" } if @filters
    p
  end
end
