require 'albacore/cross_platform_cmd'
require 'albacore/paths'

module Albacore
  module DSL
    # this means that you can use all things available in the cross platform
    # cmd from within albacore
    include Albacore::CrossPlatformCmd
    
    private

    # a rake task type for outputting assembly versions
    def asmver *args, &block
      require 'albacore/task_types/asmver'
      Albacore.define_task *args do
        c = Albacore::Asmver::Config.new
        yield c
        Albacore::Asmver::Task.new(c.opts).execute
      end
    end

    def asmver_files *args, &block
      require 'albacore/task_types/asmver'
      Albacore.define_task *args do
        c = Albacore::Asmver::MultipleFilesConfig.new
        yield c

        c.configurations.each do |conf|
          trace { "generating asmver for #{conf}" }
          Albacore::Asmver::Task.new(conf.opts).execute
        end
      end
    end

    # a task for building sln or proj files - or just invoking something
    # with MsBuild
    def build *args, &block
      require 'albacore/task_types/build'
      Albacore.define_task *args do
        c = Albacore::Build::Config.new
        yield c

        fail "unable to find MsBuild or XBuild" unless c.exe
        command = Albacore::Build::Cmd.new(c.work_dir, c.exe, c.parameters)
        Albacore::Build::Task.new(command).execute
      end
    end

    # restore the nugets to the solution
    def nugets_restore *args, &block
      require 'albacore/task_types/nugets_restore'
      Albacore.define_task *args do
        c = Albacore::NugetsRestore::Config.new
        yield c

        c.ensure_authentication! 

        c.packages.each do |p|
          command = Albacore::NugetsRestore::Cmd.new(c.work_dir, c.exe, c.opts_for_pkgcfg(p))
          Albacore::NugetsRestore::Task.new(command).execute
        end
      end
    end
    
    # pack nugets
    def nugets_pack *args, &block
      require 'albacore/task_types/nugets_pack'
      Albacore.define_task *args do
        c = Albacore::NugetsPack::Config.new
        yield c
        Albacore::NugetsPack::ProjectTask.new(c.opts).execute
      end
    end

    # basically a command with some parameters; allows you to execute your
    # tests with albacore
    def test_runner *args, &block
      require 'albacore/task_types/test_runner'
      Albacore.define_task *args do
        c = Albacore::TestRunner::Config.new
        yield c
        Albacore::TestRunner::Task.new(c.opts).execute
      end
    end

    # Restore hint paths to registered nugets
    def restore_hint_paths *args, &block
      require 'albacore/tools/restore_hint_paths'
      Albacore.define_task *args do
        c = Albacore::RestoreHintPaths::Config.new
        yield c

        t = Albacore::RestoreHintPaths::Task.new c
        t.execute
      end
    end

    # Generate .rpm or .deb files from .appspec files
    def fpm_gen *args, &block
      require 'albacore/fpm_app_spec'
      Albacore.define_task *args do
        c = ::Albacore::FpmAppSpec::Config.new
        yield c
        ::Albacore::FpmAppSpec::Task.new(c.opts).execute
      end
    end
  end
end

self.extend Albacore::DSL
