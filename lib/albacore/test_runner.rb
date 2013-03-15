require 'rake'
require 'set'
require 'albacore/cmd_config'
require 'albacore/cross_platform_cmd'

module Albacore
  module TestRunner
    class Cmd
      include CrossPlatformCmd
      def initialize work_dir, executable, parameters, file
        @work_dir, @executable = work_dir, executable
        @parameters = parameters.to_a.unshift(file)
        mono_command
      end
      def execute
        sh @work_dir, make_command
      end
    end
    class Config
      include CmdConfig
      attr_writer :files
      def files
        if @files.respond_to? :each
          @files
        else
          [@files]
        end
      end
    end
    class Task
      def initialize command_line
        @command_line = command_line
      end
      def execute
        @command_line.execute
      end
    end
  end
end
