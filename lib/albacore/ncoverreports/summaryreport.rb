module NCover
  class SummaryReport < NCover::ReportBase
    def initialize(params = {})
      @report_type = :Summary
      @report_format = :Html
      super(params)
    end
  end
end
