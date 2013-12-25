require 'ostruct'
require 'albacore/support/openstruct'

module Configuration
  module NuGetPack
    include Albacore::Configuration

    def nugetpack
      @config ||= OpenStruct.new.extend(OpenStructToHash).extend(NuGetPack)
      yield(@config) if block_given?
      @config
    end
  end
end
