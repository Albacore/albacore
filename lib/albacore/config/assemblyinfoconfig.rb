require 'ostruct'
require 'albacore/support/openstruct'

module Configuration
  module AssemblyInfo
    include Albacore::Configuration
    
    def assemblyinfo
      @config ||= OpenStruct.new.extend(OpenStructToHash).extend(AssemblyInfo)
      yield(@config) if block_given?
      @config
    end
  end
end
