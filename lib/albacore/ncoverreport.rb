require "albacore/ncoverreports"
require "albacore/albacoretask"

class NCoverReport
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
    
    result = run_command("NCover.Reporting", build_parameters)
    fail_with_message("NCover Report failed, see the build log for more details.") unless result
  end
  
  def build_parameters
    p = []
    p << @coverage_files.map{ |f| "\"#{f}\"" } if @coverage_files
    p << @reports.map { |r| get_report_options(r) } if @reports
    p << @required_coverage.map{ |c| "//mc #{c.get_coverage_options}" } if @required_coverage
    p << @filters.map{ |f| "//cf #{f.get_filter_options}" } if @filters
    p
  end
  
  def get_report_options(report)
    opts = "//or #{report.report_type}"
    opts << ":#{report.report_format}" if report.report_format
    opts << ":\"#{report.output_path}\"" if report.output_path
    opts
  end
end
