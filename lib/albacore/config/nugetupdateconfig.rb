require 'ostruct'
require 'albacore/support/openstruct'

module Configuration
  module NuGetUpdate
    include Albacore::Configuration

    def nugetupdate
      @config ||= OpenStruct.new.extend(OpenStructToHash).extend(NuGetUpdate)
      yield(@config) if block_given?
      @config
    end
  end
end