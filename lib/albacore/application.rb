require 'rake'
require 'time'

module Albacore
  class Application

    # the logger instance for this application
    attr_reader :logger

    # the output IO for this application, defaults to
    # STDOUT
    attr_reader :output

    # the standard IO error output
    attr_reader :output_err
    
    # initialize a new albacore application with a given log IO object
    def initialize log = STDOUT, output = STDOUT, output_err = STDERR
      raise ArgumentError, "log must not be nil" unless log
      raise ArgumentError, "output must not be nil" unless output
      raise ArgumentError, "out_err must not be nil" unless output_err
      @logger = Logger.new log
      @logger.level = Logger::INFO
      @logger.formatter = proc do |severity, datetime, progname, msg|
        "#{severity[0]} #{datetime.to_datetime.iso8601(6)}: #{msg}\n"
      end
      @output = output
      @output_err = output_err
    end

    def define_task *args, &block
      Rake::Task.define_task *args, &block
    end

    # wite a line to stdout
    def puts *args
      @output.puts *args 
    end
    
    # write a line to stderr
    def err *args
      @output_err.puts *args
    end
  end
end
