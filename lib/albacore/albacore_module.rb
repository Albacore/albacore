require 'albacore/application'

module Albacore
  class << self
    def application
      @application ||= Albacore::Application.new
    end
  
    # Set the global albacore logging level
    def log_level= level
      @level = level.is_a?(Albacore::Logging::LogLevel) ? level : Albacore::Logging::LogLevel.new(level)
    end
  end
end