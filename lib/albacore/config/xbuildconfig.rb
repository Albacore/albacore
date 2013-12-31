require "ostruct"
require "albacore/support/openstruct"

module Configuration
  module XBuild
    include Albacore::Configuration

    def self.xbuildconfig
      @config ||= OpenStruct.new.extend(OpenStructToHash).extend(XBuild)
    end

    def xbuild
      config ||= XBuild.xbuildconfig
      yield(config) if block_given?
      config
    end
  end
end
