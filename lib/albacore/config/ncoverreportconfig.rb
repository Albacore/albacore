require "ostruct"
require "albacore/support/openstruct"

module Configuration
  module NCoverReport
    include Albacore::Configuration

    def self.ncoverreportconfig
      @config ||= OpenStruct.new.extend(OpenStructToHash).extend(NCoverReport)
    end

    def ncoverreport
      config ||= NCoverReport.ncoverreportconfig
      yield(config) if block_given?
      config
    end
  end
end
