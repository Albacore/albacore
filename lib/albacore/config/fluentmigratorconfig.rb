require "albacore/support/openstruct"

module Configuration
  module FluentMigrator
    include Albacore::Configuration

    def self.fluentmigratorconfig
      @config ||= OpenStruct.new.extend(OpenStructToHash).extend(FluentMigrator)
    end

    def fluentmigrator
      config ||= FluentMigrator.fluentmigratorconfig
      yield(config) if block_given?
      config
    end
  end
end


