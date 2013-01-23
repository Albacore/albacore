require 'rake'
require 'map'

require 'albacore/logging'

module Albacore
  # module for normalizing slashes across operating systems
  # and running commands
  module CrossPlatformCmd
    include Logging

    class << self
      include CrossPlatformCmd
    end

    def normalize_slashes path
      Paths.normalize_slashes path
    end

    # create
    def make_command
      Paths.make_command @executable, @parameters
    end
    
    # run process - cmd should be appropriately quoted
    #
    # options:
    #  :work_dir => a file path
    #
    def system cmd, *opts
      opts = Map.options(opts || {})
      sys = ::Rake::Win32.windows? ? Rake::Win32.method(:rake_system) : Kernel.method(:system)
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
        debug "#{cmd}"
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
      
      system which
    end
    
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
end
