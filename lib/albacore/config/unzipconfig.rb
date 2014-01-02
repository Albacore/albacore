require "ostruct"
require "albacore/support/openstruct"

module Configuration
  module Unzip
    include Albacore::Configuration

    def self.unzipconfig
      @config ||= OpenStruct.new.extend(OpenStructToHash).extend(Unzip)
    end

    def unzip
      config ||= Unzip.unzipconfig
      yield(config) if block_given?
      config
    end
  end
end

