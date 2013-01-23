# -*- encoding: utf-8 -*-

require 'rake'
require 'map'
require 'albacore/logging'

module Albacore
  # module for normalizing slashes across operating systems
  # and running commands
  module CrossPlatformCmd

    class << self
      include Logging

      # run process - cmd should be appropriately quoted
      #
      # options:
      #  :work_dir => a file path
      #
      def system cmd, *opts
        opts = Map.options(opts || {})
        sys = ::Rake::Win32.windows? ? Rake::Win32.method(:rake_system) : Kernel.method(:system)
        res = nil
        chdir opts[:work_dir] do
          debug cmd
          return sys.call cmd
        end
      end

      # run in shell
      def sh work_dir = nil, cmd, &block
        raise ArgumentError, "cmd is nil" unless cmd
        sys = ::Rake::Win32.windows? ? Rake::Win32.method(:rake_system) : Kernel.method(:system)
        block = lambda { |ok, status| ok or fail(format_failure(cmd, status)) } unless block_given?
        chdir work_dir do
          debug cmd
          res = sys.call cmd
          return block.call(res, $?)
        end
      end
      
      # shell ignore exit code
      # returns:
      #  [ok, status]
      #  where status:
      #    #exitstatus : Int
      #    #pid      : Int
      def shie work_dir = nil, cmd, &block
        raise ArgumentError, "cmd is nil" unless cmd
        block = lambda { |ok, status| [ok, status] } unless block_given?
        sh work_dir, cmd, &block
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
        
        CrossPlatformCmd.system which
      end
      
      private
      def chdir wd, &block
        return block.call if wd.nil?
        Dir.chdir wd do
          debug "pushd #{wd}"
          res = block.call
          debug "popd #{wd}"
          return res
        end
      end
      
      # private(format_failure)
      def format_failure cmd, status
        "Command failed with status (#{status.exitstatus}): [#{cmd}]"
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
    def sh work_dir = nil, cmd = nil, &block
      CrossPlatformCmd.sh work_dir, (cmd || make_command), &block
    end
    
    # shell ignore exit code
    def shie work_dir = nil, cmd, &block
      CrossPlatformCmd.shie work_dir, cmd, &block
    end
    
    # redefine the Kernel.system method so that this method is used instead
    alias_method :kernel_system, :system
    
    # start a process with the command and arguments given
    def system *cmd, opts
      CrossPlatformCmd.system *cmd, opts
    end
  end
end
