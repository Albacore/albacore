require "ostruct"
require "albacore/support/openstruct"

module Configuration
  module NuGetInstall
    include Albacore::Configuration

    def self.nugetinstallconfig
      @config ||= OpenStruct.new.extend(OpenStructToHash).extend(NuGetInstall)
    end

    def nugetinstall
      config ||= NuGetInstall.nugetinstallconfig
      yield(config) if block_given?
      config
    end
  end
end
