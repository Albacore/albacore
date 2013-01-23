require 'albacore/application'
require 'albacore/dsl'

# The albacore module instance methods.
module Albacore
  class << self
		# Accessor for the Albacore application. Configuration
		# and similar singleton values will be stored in this
		# instance. Multiple calls will yield the same instance.
		# Albacore::Application is thread-safe.
    def application
      @application ||= Albacore::Application.new
    end
  
		# Defines a new task with all of what that entails:
		# will call application.define_task. 
	  def define_task *args, &block
			# delegate to the application singleton
			application.define_task *args, &block
		end

    # Set the global albacore logging level.
    def log_level= level
      @level = level.is_a?(Albacore::Logging::LogLevel) ? level : Albacore::Logging::LogLevel.new(level)
    end
  end
end
