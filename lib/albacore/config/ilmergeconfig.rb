 require 'ostruct'
require 'albacore/config/netversion'
require 'albacore/support/openstruct'

module Configuration
  module ILMerge
    include Albacore::Configuration
    
    def ilmerge
      @config ||= OpenStruct.new.extend(OpenStructToHash).extend(ILMerge)
      yield(@config) if block_given?
      @config
    end
  end
end