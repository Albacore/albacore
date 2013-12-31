require "ostruct"
require "albacore/support/openstruct"

module Configuration
  module PLink
    include Albacore::Configuration

    def self.plinkconfig
      @config ||= OpenStruct.new.extend(OpenStructToHash).extend(PLink)
    end

    def plink
      config ||= PLink.plinkconfig
      yield(config) if block_given?
      config
    end
  end
end
