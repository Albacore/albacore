require 'rake'
require 'map'
require 'processpilot/processpilot'

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
    
    # extended make command - pass:
    # exe - executable to run
    # pars - parameters
    def make_command_e exe, pars
      Paths.make_command exe, pars
    end

    # run process - cmd should be appropriately quoted
    #
    # options:
    #  :work_dir => a file path
    #
    def system *opts, &block
      cmd = opts[0]
      opts = Map.options(opts[1..-1] || {})
      sys = ::Rake::Win32.windows? ? Rake::Win32.method(:rake_system) : Kernel.method(:system)

      block = lambda { |ok, status| 
        debug "[#{cmd}] => #{status}" if opts.getopt(:verbose, false)
        return ok unless opts.getopt(:ensure_success, false)
        ok or fail(format_failure(cmd, status))
      } unless block_given?

      chdir opts[:work_dir] do
        opts.delete :work_dir if opts.has_key? :work_dir
        debug cmd unless opts.getopt(:silent, false)
        res = sys.call cmd
        return block.call(res, $?)
      end
    end
    
    def system_control cmd, *opts, &block
      cmd = opts[0]
      opts = Map.options(opts[1..-1] || {})
      chdir opts[:work_dir] do
        debug cmd
        opts.delete :work_dir if opts.has_key? :work_dir
        ProcessPilot::pilot cmd, opts, &block
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
      
      system which, :silent => true
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

    # shuffle the executable to be a parameter to
    # mono, if not on windows.
    def mono_command
      unless ::Rake::Win32.windows?
        trace 'detected running on mono -- unshifting exe file for mono'
        executable = @executable
        @executable = "mono"
        @parameters.unshift executable
      end
    end
  end
end
