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
    @coverage_files = []
    @reports = []
    @required_coverage = []
    @filters = []
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
    p << build_coverage_files if @coverage_files
    p << build_reports if @reports
    p << build_required_coverage if @required_coverage
    p << build_filters if @filters
    p
  end
  
  def build_filters
    @filters.map{|f| "//cf #{f.get_filter_options}"}.join(" ")
  end
  
  def build_coverage_files
    @coverage_files.map{|f| "\"#{f}\""}.join(" ")
  end
  
  def build_reports
    @reports.map{|r|
      report = "//or #{r.report_type}"
      report << ":#{r.report_format}" unless r.report_format.nil?
      report << ":\"#{r.output_path}\"" unless r.output_path.nil?
      report
    }.join(" ")
  end

  def build_required_coverage
    @required_coverage.map{|c|
      coverage = "//mc #{c.get_coverage_options}"
    }.join(" ")
  end
end
