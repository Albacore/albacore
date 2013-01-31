require 'albacore/asmver'
require 'albacore/cross_platform_cmd'

module Albacore
  module DSL
    include Albacore::CrossPlatformCmd
    
    private

    # a rake task type for outputting assembly versions
    def asmver *args, &block
      require 'albacore/asmver'
      args ||= []

      c = Albacore::AsmVer::Config.new
      yield c if block_given?
      
      body = proc {
        c.projects.each { |p|
          cmd = Albacore::AsmVer::Cmd.new p
          Albacore::AsmVer::Task.new(cmd).execute
        }
      }
      
      Albacore.define_task *args, &body
    end

    def build *args, &block
      require 'albacore/build'
      args ||= []

      c = Albacore::Build::Config.new
      yield c

      body = proc {
        fail "unable to find MsBuild or XBuild" unless c.exe
        command = Albacore::Build::Cmd.new(c.work_dir, c.exe, c.parameters)
        Albacore::Build::Task.new(command).execute
      }

      Albacore.define_task *args, &body
    end

    def nugets_restore *args, &block
      require 'albacore/nugets_restore'
      args ||= []
      
      c = Albacore::NugetsRestore::Config.new
      yield c

      body = proc {
        c.packages.each do |p|
          normalized_p = Albacore::Paths.normalize_slashes p
          command = Albacore::NugetsRestore::Cmd.new(c.work_dir, c.exe, normalized_p, c.out)
          Albacore::NugetsRestore::Task.new(command).execute
        end
      }

      Albacore.define_task(*args, &body)
    end
    
    def nugets_path *args, &block
      
    end

    def restore_hint_paths *args, &block
      require 'albacore/restore_hint_paths'
      args ||= []
      
      c = Albacore::RestoreHintPaths::Config.new
      yield c
      
      body = proc {
        t = Albacore::RestoreHintPaths::Task.new c
        t.execute
      }
      
      Albacore.define_task(*args, &body)
    end

    def test_runner *args, &block
      require 'albacore/test_runner'
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

      Albacore.define_task(*args, &body)
    end
  end
end

self.extend Albacore::DSL
