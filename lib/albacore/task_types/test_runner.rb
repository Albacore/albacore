require 'set'
require 'map'
require 'tmpdir'
require 'fileutils'
require 'pathname'
require 'albacore/cmd_config'
require 'albacore/cross_platform_cmd'

module Albacore
  module TestRunner
    class Cmd
      include CrossPlatformCmd
      def initialize work_dir, executable, parameters, file
        @work_dir, @executable = work_dir, executable
        @parameters = parameters.to_a.unshift(file)
      end

      def execute
        system @executable,
          @parameters,
          :work_dir    => @work_dir,
          :clr_command => true
      end
    end

    # the configuration object for the test runner
    class Config
      include CmdConfig

      # give this property the list of dlls you want to test
      attr_writer :files

      # constructor, no parameters
      def initialize
        @copy_local = false
        @files = []
      end

      # gets the configured options
      def opts
        Map.new(
          :files      => files,
          :copy_local => @copy_local,
          :exe        => @exe)
      end

      # mark that it should be possible to copy the test files local
      # -- this is great if you are running a VM and the host disk is
      # mapped as a network drive, which crashes some test runners
      def copy_local
        @copy_local = true
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

    class Task
      include Logging

      def initialize opts
        @opts = opts
      end

      def execute
        raise ArgumentError, 'missing :exe' unless @opts.get :exe
        raise ArgumentError, 'missing :files' unless @opts.get :files
        @opts.get(:files).each do |dll|
          raise ArgumentError, "could not find test dll '#{dll}' in dir #{FileUtils.pwd}" unless File.exists? dll
          execute_tests_for dll
        end
      end

      private
      def execute_tests_for dll
        handle_directory dll, @opts.get(:exe) do |dir, exe|
          filename = File.basename dll
          cmd = Albacore::TestRunner::Cmd.new dir, exe, @opts.get(:parameters, []), filename
          cmd.execute
        end
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

            # call back with the new paths
            yield [sut, Paths.join(runners, File.basename(exe)).to_s]
          end
        else
          yield [File.dirname(dll), exe]
        end
      end
    end
  end
end
