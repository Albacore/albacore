require "ostruct"
require "albacore/support/openstruct"

module Configuration
  module Nuspec
    include Albacore::Configuration
    
    def self.nuspecconfig
      @config ||= OpenStruct.new.extend(OpenStructToHash).extend(Nuspec)
    end
    
    def nuspec
      config ||= Nuspec.nuspecconfig
      yield(config) if block_given?
      config
    end
  end
end
