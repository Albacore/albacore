require 'rake'
require 'albacore/paths'
require 'albacore/cmd_config'
require 'albacore/cross_platform_cmd'

module Albacore
  module NugetsPack
    class Cmd
      include CrossPlatformCmd
      def initialize work_dir, executable, out, opts
        opts = Map.options(opts)
        
      end
      def execute
        
      end
    end
    class Config
      include CmdConfig
      
      # the output directory to place the newfangled nugets in
      attr_accessor :out
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