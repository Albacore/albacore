require "ostruct"
require "albacore/support/openstruct"

module Configuration
  module NCoverConsole
    include Albacore::Configuration

    def self.ncoverconsoleconfig
      @config ||= OpenStruct.new.extend(OpenStructToHash).extend(NCoverConsole)
    end

    def ncoverconsole
      config ||= NCoverConsole.ncoverconsoleconfig
      yield(config) if block_given?
      config
    end
  end
end

