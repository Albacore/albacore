# -*- encoding: utf-8 -*-

require 'rake'
require 'set'
require 'albacore/paths'
require 'albacore/cmd_config'
require 'albacore/cross_platform_cmd'

module Albacore
  module TestRunner
    class Cmd
      include Logging
      include CrossPlatformCmd
      def initialize work_dir, executable, parameters, file
        @work_dir, @executable = work_dir, executable
        @parameters = parameters.unshift(file)
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

def test_runner *args
  args ||= []
  
  c = Albacore::TestRunner::Config.new
  yield c

  body = proc {
    # Albacore::Paths.normalize_slashes p
    c.files.each { |dll|
      command = Albacore::TestRunner::Cmd.new c.work_dir, c.exe, c.parameters, dll
      Albacore::TestRunner::Task.new(command).execute
    }
  }

  Rake::Task.define_task(*args, &body)
end