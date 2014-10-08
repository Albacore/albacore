require 'albacore/version'

module Albacore
  class Cli
    include Albacore::CliDSL

    def initialize args
      # Run a semver command. Raise a CommandError if the command does not exist.
      # Expects an array of commands, such as ARGV.
      def initialize(*args)
      @args = args
      run_command(@args.shift || :help)
    end

    private

    def next_param_or_error(error_message)
      @args.shift || raise(CommandError, error_message)
    end

    # Gets the help text if the command line is used in the wrong way
    def help_text
      <<-HELP
albacore commands
-----------------

init[ialze]                        # initialize a new Rakefile with defaults
help                               # display this help

PLEASE READ https://github.com/Albacore/albacore/wiki/Albacore-binary
      HELP
    end

    # Create a new Rakefile file if the file does not exist.
    command :initialize, :init do
      if File.exist? 'Rakefile'
        puts 'Rakefile already exists'
      else
        File.open 'Gemfile', 'w+' do |io|
          io.puts <<-DATA
source 'https://rubygems.org'
gem 'albacore', '~> #{Albacore.version}'
          DATA
        end
      end
    end
  end
end

module Albacore
  module CliDSL

    def self.included(klass)
      klass.extend ClassMethods
      klass.send :include, InstanceMethods
    end

    class CommandError < StandardError
    end

    module InstanceMethods
      # Calls an instance method defined via the ::command class method.
      # Raises CommandError if the command does not exist.
      def run_command(command)
        method_name = "#{self.class.command_prefix}#{command}"
        if self.class.method_defined?(method_name)
          send method_name
        else
          raise CommandError, "invalid command #{command}"
        end
      end
    end

    module ClassMethods
      # Defines an instance method based on the first command name.
      # The method executes the code of the given block.
      # Aliases methods for any subsequent command names.
      def command(*command_names, &block)
        method_name = "#{command_prefix}#{command_names.shift}"
        define_method method_name, &block
        command_names.each do |c|
          alias_method "#{command_prefix}#{c}", method_name
        end
      end

      # The prefix for any instance method defined by the ::command method.
      def command_prefix
        :_run_
      end
    end
  end
end