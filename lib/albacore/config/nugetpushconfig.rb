require 'ostruct'
require 'albacore/support/openstruct'

module Configuration
  module NuGetPush
    include Albacore::Configuration

    def nugetpush
      @config ||= OpenStruct.new.extend(OpenStructToHash).extend(NuGetPush)
      yield(@config) if block_given?
      @config
    end
  end
end
