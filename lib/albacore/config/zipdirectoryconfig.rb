require "ostruct"
require "albacore/support/openstruct"

module Configuration
  module Zip
    include Albacore::Configuration

    def self.zipconfig
      @config ||= OpenStruct.new.extend(OpenStructToHash).extend(Zip)
    end

    def zip
      config ||= Zip.zipconfig
      yield(config) if block_given?
      config
    end
  end
end
