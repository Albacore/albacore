require "ostruct"
require "albacore/support/openstruct"

module Configuration
  module SQLCmd
    include Albacore::Configuration

    def self.sqlcmdconfig
      @config ||= OpenStruct.new.extend(OpenStructToHash).extend(SQLCmd)
    end

    def sqlcmd
      config ||= SQLCmd.sqlcmdconfig
      yield(config) if block_given?
      config
    end
  end
end
