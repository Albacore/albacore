require 'albacore/application'

# The albacore module instance methods.
module Albacore
  class << self
    # Accessor for the Albacore application. Configuration
    # and similar singleton values will be stored in this
    # instance. Multiple calls will yield the same instance.
    def application
      @application ||= Albacore::Application.new
    end

    # set the application -- good for testing
    # the infrastructure of albacore by resetting the
    # state after each test
    def set_application app
      @application = app
    end

    # Defines a new task with all of what that entails:
    # will call application.define_task.
    def define_task *args, &block
      # delegate to the application singleton
      application.define_task *args, &block
    end

    # Set the global albacore logging level.
    def log_level= level
      application.logger.level = level
    end

    # Use to write to STDOUT (by default)
    def puts *args
      application.puts *args
    end

    def events
      @events ||= {}
    end

    def subscribe event, &block
      event = event.to_sym unless event.is_a? Symbol
      events[event] ||= Set.new
      events[event].add block
    end

    def publish event, obj
      if events.member? event
        events[event].each { |m| m.call(obj) }
      end
    end
  end
end
