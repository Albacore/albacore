require 'rake'
require 'albacore/paths'
require 'albacore/cmd_config'
require 'albacore/cross_platform_cmd'

module Albacore
  module NugetsRestore
    class Cmd
      include CrossPlatformCmd
      def initialize work_dir, executable, package, out, parameters
        @work_dir = work_dir
        @executable = executable
        @parameters = [%W{install #{package} -OutputDirectory #{out}}, parameters.to_a].flatten
      end
      def execute
        sh @work_dir, make_command
      end
    end
    
    # #work_dir: optional
    # #exe: required NuGet.exe path
    # #out: required location of 'packages' folder
    class Config
      include CmdConfig
    
      # the output directory passed to nuget when restoring the nugets
      attr_accessor :out
    
      def packages
        list_spec = File.join '**', 'packages.config'
        # it seems FileList doesn't care about the curr dir
        in_work_dir do FileList[Dir.glob(list_spec)] end
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
