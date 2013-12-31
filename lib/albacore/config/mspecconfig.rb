require "ostruct"
require "albacore/support/openstruct"

module Configuration
  module MSpec
    include Albacore::Configuration

    def self.mspecconfig
      @config ||= OpenStruct.new.extend(OpenStructToHash).extend(MSpec)
    end

    def mspec
      config ||= MSpec.mspecconfig
      yield(config) if block_given?
      config
    end
  end
end

