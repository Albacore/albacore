module NCover
  class FullCoverageReport < NCover::ReportBase
    def initialize(params = {})
      @report_type = :FullCoverageReport
      @report_format = :Html
      super(params)
    end
  end
end
