require "ostruct"
require "albacore/support/openstruct"

module Configuration
  module NDepend
    include Albacore::Configuration

    def self.ndependconfig
      @config ||= OpenStruct.new.extend(OpenStructToHash).extend(NDepend)
    end

    def ndepend
      config ||= NDepend.ndependconfig
      yield(config) if block_given?
      config
    end
  end
end

