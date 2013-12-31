require "ostruct"
require "albacore/support/openstruct"

module Configuration
  module MSTest
    include Albacore::Configuration

    def self.mstestconfig
      @config ||= OpenStruct.new.extend(OpenStructToHash).extend(MSTest)
    end

    def mstest
      config ||= MSTest.mstestconfig
      yield(config) if block_given?
      config
    end
  end
end

