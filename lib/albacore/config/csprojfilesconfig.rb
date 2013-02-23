require 'ostruct'
require 'albacore/support/openstruct'

module Configuration
  module CsProjFiles
    include Albacore::Configuration

    def csprojfiles
      @csprojfilesconfig ||= OpenStruct.new.extend(OpenStructToHash).extend(CsProjFiles)
      yield(@csprojfilesconfig) if block_given?
      @csprojfilesconfig
    end
  end
end

