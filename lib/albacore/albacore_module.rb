# -*- encoding: utf-8 -*-

require 'albacore/application'
require 'albacore/logging'

# The albacore module instance methods.
module Albacore
  class << self
    # Accessor for the Albacore application. Configuration
    # and similar singleton values will be stored in this
    # instance. Multiple calls will yield the same instance.
    def application
      @application ||= Albacore::Application.new
    end

    # Name of default Rakefile, used by Cli
    def rakefile
      'Rakefile'
    end

    # Name of the default Gemfile, used by Cli
    def gemfile
      'Gemfile'
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
      args = [caller[0][/`.*'/][1..-2]] if args.nil? or args.empty?
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

    # Gets whether we're running under Windows.
    #
    def windows?
      !!::Rake::Win32.windows?
    end

    Albacore.log_level = Logger::DEBUG if ENV["DEBUG"]
  end
end
