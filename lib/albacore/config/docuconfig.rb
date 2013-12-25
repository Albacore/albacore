require 'ostruct'
require 'albacore/support/openstruct'

module Configuration
  module Docu
    include Albacore::Configuration
    
    def docu
      @docuconfig ||= OpenStruct.new.extend(OpenStructToHash)
      yield(@config) if block_given?
      @config
    end
  end
end

