require "ostruct"
require "albacore/support/openstruct"

module Configuration
  module NAnt
    include Albacore::Configuration

    def self.nantconfig
      @config ||= OpenStruct.new.extend(OpenStructToHash).extend(NAnt)
    end

    def nant
      config ||= NAnt.nantconfig
      yield(config) if block_given?
      config
    end
  end
end
