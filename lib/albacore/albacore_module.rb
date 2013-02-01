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

    def subscribe event, &block
    	event = event.to_sym unless event.is_a? Symbol
      @events ||= {}
      @events[event] ||= Set.new
      @events[event].add block 
    end

    def publish event, obj
      if @events.member? event
        @events[event].each { |m| m.call(obj) }
      end
    end
  end
end
