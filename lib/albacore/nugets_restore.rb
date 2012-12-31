# -*- encoding: utf-8 -*-

require 'rake'
require 'albacore/paths'
require 'albacore/cmd_config'
require 'albacore/cross_platform_cmd'

module Albacore
  module NuGetsRestore
    class Cmd
      include CrossPlatformCmd
      def initialize work_dir, executable, package, out
        @work_dir = work_dir
        @executable = executable
        @parameters = %W{install #{package} -OutputDirectory #{out}}
      end
      def execute
        sh @work_dir, make_command
      end
    end
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

def restore_nugets *args
  args ||= []
  
  c = Albacore::NuGetsRestore::Config.new
  yield c

  body = proc {
    c.packages.each do |p|
      normalized_p = Albacore::Paths.normalize_slashes p
      command = Albacore::NuGetsRestore::Cmd.new(c.work_dir, c.exe, normalized_p, c.out)
      Albacore::NuGetsRestore::Task.new(command).execute
	  end
  }

  Rake::Task.define_task(*args, &body)
end