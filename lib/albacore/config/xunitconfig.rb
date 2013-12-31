require 'ostruct'
require 'albacore/support/openstruct'

module Configuration
  module XUnit
    include Albacore::Configuration

    def self.xunitconfig
      @config ||= OpenStruct.new.extend(OpenStructToHash).extend(XUnit)
    end

    def xunit
      config ||= XUnit.xunitconfig
      yield(config) if block_given?
      config
    end
  end
end
