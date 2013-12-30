require "ostruct"
require "albacore/support/openstruct"

module Configuration
  module Docu
    include Albacore::Configuration
    
    def self.docuconfig
      @config ||= OpenStruct.new.extend(OpenStructToHash).extend(Docu)
    end

    def docu
      config ||= Docu.docuconfig
      yield(config) if block_given?
      config
    end
  end
end

