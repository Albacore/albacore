require 'ostruct'
require 'albacore/support/openstruct'

module Configuration
  module SpecFlowReport
    include Albacore::Configuration

    def specflowreport
      @specflowreportconfig ||= OpenStruct.new.extend(OpenStructToHash)
      yield(@specflowreportconfig) if block_given?
      @specflowreportconfig
    end
  end
end
