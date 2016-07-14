require 'set'
require 'map'
require 'tmpdir'
require 'fileutils'
require 'pathname'
require 'albacore/cmd_config'
require 'albacore/cross_platform_cmd'
require 'albacore/paths'

module Albacore
  module TestRunner
    # the configuration object for the test runner
    class Config
      include CmdConfig
      self.extend ConfigDSL

      # give this property the list of dlls you want to test
      attr_writer :files

      # give this property the settings file for the dlls you want to test
      attr_writer :settings

      # constructor, no parameters
      def initialize
        @parameters = Set.new
        @copy_local = false
        @is_ms_test = false
        @clr_command = true
        @execute_as_batch = false
        @files = []
      end

      # Gets the configured options from the test runner configuration.
      #
      def opts
        Map.new(
          :files => files,
          :copy_local  => @copy_local,
          :is_ms_test  => @is_ms_test, 
          :exe         => @exe,
          :parameters  => @parameters,
          :clr_command => @clr_command,
          :execute_as_batch => @execute_as_batch)
      end

      attr_path_accessor :settings do |s|
        @parameters.add("/testsettings:#{s}")
      end

      # Mark that it should be possible to copy the test files local
      # -- this is great if you are running a VM and the host disk is
      # mapped as a network drive, which crashes some test runners
      def copy_local
        @copy_local = true
      end

      # Call this on the confiuguration if you don't want 'mono' prefixed to the
      # exe path on non-windows systems.
      #
      def native_exe
        @clr_command = false
      end

      def is_ms_test
        @is_ms_test = true
      end 

      # Will cause the executable to be run only once, testing all files as a batch.
      def execute_as_batch
        @execute_as_batch = true
      end

      private
      def files
        if @files.respond_to? :each
          @files
        else
          [@files]
        end
      end
    end

    class Cmd
      include CrossPlatformCmd

      # expects both parameters and executable to be relative to the
      # work_dir parameter
      def initialize work_dir, executable, parameters, files, clr_command = true
        @work_dir, @executable = work_dir, executable
        @parameters = files.concat(parameters.to_a)
        @clr_command = clr_command
      end

      def execute
        info { "executing in directory '#{@work_dir}'" }
        system @executable,
          @parameters,
          :work_dir    => @work_dir,
          :clr_command => @clr_command
      end
    end

    class Task
      include Logging

      def initialize opts
        @opts = opts
      end

      def execute
        raise ArgumentError, 'missing :exe' unless @opts.get :exe
        raise ArgumentError, 'missing :files' unless @opts.get :files
        raise ArgumentError, 'cannot specify both execute_as_batch and is_ms_test' if @opts.get :execute_as_batch and @opts.get :is_ms_test
        raise ArgumentError, 'cannot specify both execute_as_batch and is_ms_test' if @opts.get :execute_as_batch and @opts.get :copy_local

        @opts.get(:files).each do |dll|
          raise ArgumentError, "could not find test dll '#{dll}' in dir #{FileUtils.pwd}" unless File.exists? dll
        end

        commands = []
        if @opts.get(:execute_as_batch)
          commands = build_command_for_all_dlls
        else
          commands = @opts.get(:files).map { |dll| build_command_for dll }
        end

        execute_commands commands
      end

      private
      def execute_commands commands
        commands.each { |command| command.execute }
      end

      def build_command_for dll
        handle_directory dll, @opts.get(:exe) do |dir, exe|
          filename = File.basename dll
          
          if @opts.get(:is_ms_test)
            filename = "/testcontainer:#{filename}"
          end
          Albacore::TestRunner::Cmd.new dir,
                                        exe,
                                        @opts.get(:parameters, []),
                                        [filename],
                                        @opts.get(:clr_command)
        end
      end

      def split_path path
        parts = []
        last_path = ''
        path, leaf = File.split path
        while path != last_path do
          last_path = path
          parts.unshift leaf
          path, leaf = File.split path
        end

        parts.unshift path
      end

      def find_common_prefix paths
        first = paths.min
        last = paths.max

        i = 0
        i = i + 1 while i < first.length and i < last.length and first[i] == last[i]
        first.slice(0, i)
      end

      def build_command_for_all_dlls
        files = @opts.get(:files)

        absolute_files = files.map { |file| File.absolute_path(file) }
        file_paths = absolute_files.map { |file| split_path file }

        common_prefix = Pathname.new(File.join(find_common_prefix file_paths))
        relative_working_directory = common_prefix.relative_path_from(Pathname.new(FileUtils.pwd))

        relative_paths = absolute_files.map { |file| (Pathname(file).relative_path_from Pathname.new(relative_working_directory.realpath())).to_s }

        exe = @opts.get(:exe)
        exe = Pathname.new(exe).relative_path_from(relative_working_directory)

        command = Albacore::TestRunner::Cmd.new relative_working_directory.to_s,
                                                exe.to_s,
                                                @opts.get(:parameters, []),
                                                relative_paths,
                                                @opts.get(:clr_command)
        [command]
      end

      def handle_directory dll, exe, &block
        if @opts.get(:copy_local)
          # TODO: #mktmpdir is not always reliable; consider contributing a patch to ruby?
          # Fails sometimes with "directory already exists"
          Dir.mktmpdir 'alba-test' do |dir|
            sut, runners = Paths.join(dir, 'sut').to_s, Paths.join(dir, 'runners').to_s
            [sut, runners].each { |d| FileUtils.mkdir_p d }

            sut_glob = Paths.join(File.dirname(dll), '*').as_unix.to_s
            debug { "copying recursively from #{sut_glob} [test_runner #handle_directory]" }
            FileUtils.cp_r(Dir.glob(sut_glob), sut, :verbose => true)

            runners_glob = Paths.join(File.dirname(exe), '*').as_unix.to_s
            debug { "copying the runners form #{runners_glob} [test_runner #handle_directory]" }
            FileUtils.cp_r(Dir.glob(runners_glob), runners, :verbose => true)

            # call back with the new paths, easy because we have copied everything
            yield [sut, Paths.join(runners, File.basename(exe)).to_s]
          end
        else
          dir, exe =
            case File.dirname dll
              when /^\.\./
                # if the dll is negative to this Rakefile, use absolute paths
                [Pathname.new(File.absolute_path(dll)), Pathname.new(File.absolute_path(exe))]
              else 
                # otherwise, please continue with the basics
                [Paths.normalise_slashes(Pathname.new(File.dirname(dll))), Pathname.new(exe)]
            end

          exe_rel = exe.relative_path_from dir
          yield [File.dirname(dll), exe_rel.to_s]
        end
      end
    end
  end
end
