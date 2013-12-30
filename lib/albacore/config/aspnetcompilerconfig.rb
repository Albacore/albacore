require "ostruct"
require "albacore/config/netversion"
require "albacore/support/openstruct"

module Configuration
  module AspNetCompiler
    include Configuration::NetVersion
    include Albacore::Configuration

    def self.aspnetcompilerconfig
      @config ||= OpenStruct.new.extend(OpenStructToHash).extend(AspNetCompiler)
    end

    def aspnetcompiler
      config ||= AspNetCompiler.aspnetcompilerconfig
      yield(config) if block_given?
      config
    end

    def self.included(mod)
      self.aspnetcompilerconfig.use :net40
    end

    def use(netversion)
      # net35 doesn't have an asp.net compiler
      netversion = :net20 if netversion == :net35
      self.command = File.join(get_net_version(netversion), "aspnet_compiler.exe")
    end
  end
end
