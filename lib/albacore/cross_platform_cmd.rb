# -*- encoding: utf-8 -*-

require 'rake'
require 'albacore/logging'

module Albacore
  # module for normalizing slashes across operating systems
  # and running commands
  module CrossPlatformCmd

    class << self
      include Logging

      def sh work_dir = nil, cmd
        raise ArgumentError, "cmd is nil" unless cmd
        sys = ::Rake::Win32.windows? ? Rake::Win32.method(:rake_system) : Kernel.method(:system)
        unless work_dir.nil?
          trace "pushd #{work_dir}"
          debug cmd
          Dir.chdir work_dir do sys.call cmd end
          trace "popd"
        else
          debug cmd
          sys.call cmd do |res, ok|
            p res
            res
          end
        end
      end
      def which executable
        raise ArgumentError, "executable is nil" unless executable

        dir = File.dirname executable
        file = File.basename executable

        parameters = []
        parameters << Paths.normalize_slashes(file) if dir == '.'
        parameters << Paths.normalize_slashes("#{dir}:#{file}") unless dir == '.'

        which = ::Rake::Win32.windows? ?
          "#{Paths.make_command 'where', parameters} >NUL 2>&1" :
          "#{Paths.make_command 'which', parameters} >/dev/null 2>&1"

        CrossPlatformCmd.sh which
      end
    end

    def normalize_slashes path
      Paths.normalize_slashes path
    end

    # create
    def make_command
      Paths.make_command @executable, @parameters
    end

    # run the command
    #
    # work_dir :: the working directory to run the command in, or nil if you want to be in the current
    #             directory.
    #
    # cmd      :: the command to run, nil if you want to have the method call make_command for you
    def sh work_dir = nil, cmd = nil
      CrossPlatformCmd.sh work_dir, (cmd || make_command)
    end
  end
end
