require 'ostruct'
require 'albacore/support/openstruct'

module Configuration
  module NuGetInstall
    include Albacore::Configuration

    def nugetinstall
      @config ||= OpenStruct.new.extend(OpenStructToHash).extend(NuGetInstall)
      yield(@config) if block_given?
      @config
    end
  end
end
