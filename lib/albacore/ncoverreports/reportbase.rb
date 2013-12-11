require "albacore/support/updateattributes"

module NCover
  class ReportBase
    include UpdateAttributes
    
    attr_accessor :output_path, :report_format, :report_type
    
    def initialize(params = {})
      update_attributes(params) if params
      super()
    end
    
    def get_report_options()
      options = "#{@report_type}"
      options << ":#{@report_format}" if @report_format
      options << ":\"#{@output_path}\"" if @output_path
      options
    end
  end
end
