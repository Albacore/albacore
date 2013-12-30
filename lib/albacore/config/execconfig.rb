require "ostruct"
require "albacore/support/openstruct"

module Configuration
  module Exec
    include Albacore::Configuration

    def self.execconfig
      @config ||= OpenStruct.new.extend(OpenStructToHash).extend(Exec)
    end

    def exec
      config ||= Exec.execconfig
      yield(config) if block_given?
      config
    end
  end
end

