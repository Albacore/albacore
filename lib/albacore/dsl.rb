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
      Albacore.define_task *args do |task_name, own_args|
        c = Albacore::Asmver::Config.new
        yield c, own_args
        Albacore::Asmver::Task.new(c.opts).execute
      end
    end

    def asmver_files *args, &block
      require 'albacore/task_types/asmver'
      Albacore.define_task *args do |task_name, own_args|
        c = Albacore::Asmver::MultipleFilesConfig.new
        yield c, own_args

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
      Albacore.define_task *args do |task_name, own_args|
        c = Albacore::Build::Config.new
        yield c, own_args

        fail "unable to find MsBuild or XBuild" unless c.exe

        c.files.each do |f|
          command = Albacore::Build::Cmd.new(c.work_dir, c.exe, c.params_for_file(f))
          Albacore::Build::Task.new(command).execute
        end
      end
    end

    # restore the nugets to the solution
    def nugets_restore *args, &block
      require 'albacore/task_types/nugets_restore'
      Albacore.define_task *args do |task_name, own_args|
        c = Albacore::NugetsRestore::Config.new
        yield c, own_args

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
      Albacore.define_task *args do |task_name, own_args|
        c = Albacore::NugetsPack::Config.new
        yield c, own_args
        Albacore::NugetsPack::ProjectTask.new(c.opts).execute
      end
    end

    # Restore hint paths to registered nugets
    def restore_hint_paths *args, &block
      require 'albacore/tools/restore_hint_paths'
      Albacore.define_task *args do |task_name, own_args|
        c = Albacore::RestoreHintPaths::Config.new
        yield c, own_args

        t = Albacore::RestoreHintPaths::Task.new c
        t.execute
      end
    end

    # Generate .rpm or .deb files from .appspec files
    def appspecs *args, &block
      if Albacore.windows?
        require 'albacore/cpack_app_spec'
        Albacore.define_task *args do |task_name, own_args|
          c = ::Albacore::CpackAppSpec::Config.new
          yield c, own_args
          ::Albacore::CpackAppSpec::Task.new(c.opts).execute
        end
      else
        require 'albacore/fpm_app_spec'
        Albacore.define_task *args do |task_name, own_args|
          c = ::Albacore::FpmAppSpec::Config.new
          yield c, own_args
          ::Albacore::FpmAppSpec::Task.new(c.opts).execute
        end
      end
    end

    # a task for publishing sql databases
    # with SqlPackage
    def sql_package *args, &block
      require 'albacore/task_types/sql_package'
      Albacore.define_task *args do |task_name, own_args|
        c = Albacore::SqlPackage::Config.new
        yield c, own_args

        fail "SqlPackage.exe is not installed.\nPlease download and install Microsoft SSDT: https://msdn.microsoft.com/en-us/library/mt204009.aspx\nAnd add the location of SqlPackage.exe to the PATH system varible." unless c.exe

        command = Albacore::SqlPackage::Cmd.new(c.work_dir, c.exe, c.parameters)
        Albacore::SqlPackage::Task.new(command).execute
      end
    end

    # a task for publishing sql scripts
    # with Sql
    def sql_cmd *args, &block
      require 'albacore/task_types/sql_cmd'
      Albacore.define_task *args do |task_name, own_args|
        c = Albacore::Sql::Config.new
        yield c, own_args
        Albacore::Sql::SqlTask.new(c.work_dir, c.opts).execute
      end
    end

    # a task for publishing Integration Services Packages
    # with IsPackage
    def is_package *args, &block
      require 'albacore/task_types/is_package'
      Albacore.define_task *args do |task_name, own_args|
        c = Albacore::IsPackage::Config.new
        yield c, own_args

        fail "IsPackage.exe is not installed.\nPlease download and install Microsoft SSDT-BI: https://msdn.microsoft.com/en-us/library/mt674919.aspx\nAnd add the location of IsPackage.exe to the PATH system varible." unless c.exe

        command = Albacore::IsPackage::Cmd.new(c.work_dir, c.exe, c.get_parameters)
        Albacore::IsPackage::Task.new(command).execute
      end
    end
  end
end

self.extend Albacore::DSL
