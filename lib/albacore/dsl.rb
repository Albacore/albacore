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

      body = proc {
        c = Albacore::AsmVer::Config.new
        yield c
      
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

      body = proc {
        c = Albacore::Build::Config.new
        yield c

        fail "unable to find MsBuild or XBuild" unless c.exe
        command = Albacore::Build::Cmd.new(c.work_dir, c.exe, c.parameters)
        Albacore::Build::Task.new(command).execute
      }

      Albacore.define_task *args, &body
    end

    def nugets_restore *args, &block
      require 'albacore/nugets_restore'
      args ||= []
      
      body = proc {
        c = Albacore::NugetsRestore::Config.new
        yield c

        c.ensure_authentication! 

        c.packages.each do |p|
          command = Albacore::NugetsRestore::Cmd.new(c.work_dir, c.exe, c.opts_for_pkgcfg(p))
          Albacore::NugetsRestore::Task.new(command).execute
        end
      }

      Albacore.define_task(*args, &body)
    end
    
    def nugets_pack *args, &block
      require 'albacore/nugets_pack'
      args ||= []
      
      body = proc {
        c = Albacore::NugetsPack::Config.new
        yield c
      
        c.files.each do |f|
          command = Albacore::NugetsPack::Cmd.new(c.work_dir, c.exe, c.out, c.opts)
          Albacore::NugetsPack::Task.new(command, c, f).execute
        end
      } 

      Albacore.define_task(*args, &body)
    end

    def restore_hint_paths *args, &block
      require 'albacore/restore_hint_paths'
      args ||= []
      
      body = proc {
        c = Albacore::RestoreHintPaths::Config.new
        yield c

        t = Albacore::RestoreHintPaths::Task.new c
        t.execute
      }
      
      Albacore.define_task(*args, &body)
    end

    def test_runner *args, &block
      require 'albacore/test_runner'
      args ||= []
      
      body = proc {
        c = Albacore::TestRunner::Config.new
        yield c

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
