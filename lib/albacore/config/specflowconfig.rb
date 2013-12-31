require "ostruct"
require "albacore/support/openstruct"

module Configuration
  module SpecFlow
    include Albacore::Configuration

    def self.specflowconfig
      @config ||= OpenStruct.new.extend(OpenStructToHash).extend(SpecFlow)
    end

    def specflow
      config ||= SpecFlow.specflowconfig
      yield(config) if block_given?
      config
    end
  end
end
