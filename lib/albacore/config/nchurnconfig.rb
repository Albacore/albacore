require "ostruct"
require "albacore/support/openstruct"

module Configuration
  module NChurn
    include Albacore::Configuration

    def self.nchurnconfig
      @config ||= OpenStruct.new.extend(OpenStructToHash).extend(NChurn)
    end

    def nchurn
      config ||= NChurn.nchurnconfig
      yield(config) if block_given?
      config
    end
  end
end

