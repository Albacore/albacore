require 'rake'
module Albacore
  class Application

    # the logger instance for this application
    attr_reader :logger

    # the output IO for this application, defaults to
    # STDOUT
    attr_reader :output
    
    # initialize a new albacore application with a given log IO object
    def initialize log = STDOUT, output = STDOUT
      raise ArgumentError, "log must not be nil" if log.nil?
      raise ArgumentError, "output must not be nil" if output.nil?
      @logger = Logger.new log
      @logger.level = Logger::INFO
      @output = output
    end

    def define_task *args, &block
      Rake::Task.define_task *args, &block
    end

    def puts *args
      @output.puts *args 
    end
  end
end
