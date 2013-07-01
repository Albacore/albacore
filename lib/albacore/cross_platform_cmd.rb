require 'rake'
require 'map'
require 'processpilot/processpilot'
require 'albacore/paths'
require 'albacore/logging'

module Albacore
  # module for normalizing slashes across operating systems
  # and running commands
  module CrossPlatformCmd
    include Logging

    # Exit status class for times the system just gives us a nil.
    class PseudoStatus
      attr_reader :exitstatus
      def initialize(code=0)
        @exitstatus = code
      end
      def to_i
        @exitstatus << 8
      end
      def >>(n)
        to_i >> n
      end
      def stopped?
        false
      end
      def exited?
        true
      end
    end

    class << self
      include CrossPlatformCmd
    end

    def normalize_slashes path
      ::Albacore::Paths.normalize_slashes path
    end

    # create
    def make_command
      ::Albacore::Paths.make_command @executable, @parameters
    end

    # run process
    # system(cmd, [args array], [opts])
    # 
    # options are passed as the last argument
    #
    # options:
    #  :work_dir => a file path
    #
    def system *cmd, &block
      raise ArgumentError, "cmd is nil" if cmd.nil? # don't allow nothing to be passed
      block = lambda { |ok, status| ok or fail(format_failure(cmd, status)) } unless block_given?
      opts = Map.options((Hash === cmd.last) ? cmd.pop : {}) # same arg parsing as rake
      pars = cmd[1..-1].flatten

      raise ArgumentError, "arguments 1..-1 must be an array" unless pars.is_a? Array

      exe, pars = ::Albacore::Paths.normalise cmd[0], pars 
      trace "system( exe=#{exe}, pars=#{pars.join(', ')}, options=#{opts.to_s})"

      chdir opts.get(:work_dir) do
        puts %Q{#{exe} #{pars.join(' ')}} unless opts.get :silent, false # log cmd verbatim
        begin
          res = IO.popen([exe, *pars]) { |io| io.readlines }
        rescue Errno::ENOENT => e
          return block.call(nil, 127)
        end
        puts res unless opts.get(:silent, false) or not opts.get(:output, true)
        return block.call($? == 0 && res, $?)
      end
    end
    
    def system_control cmd, *opts, &block
      cmd = opts[0]
      opts = Map.options((Hash === cmd.last) ? cmd.pop : {}) # same arg parsing as rake
      chdir opts[:work_dir] do
        puts cmd
        ProcessPilot::pilot cmd, opts, &block
      end
    end

    # run in shell
    def sh *cmd, &block
      raise ArgumentError, "cmd is nil" if cmd.nil? # don't allow nothing to be passed
      block = lambda { |ok, status| ok or fail(format_failure(cmd, status)) } unless block_given?

      opts = Map.options((Hash === cmd.last) ? cmd.pop : {}) # same arg parsing as rake
      cmd = cmd.join(' ') # shell needs a single string

      chdir opts.get(:work_dir) do
        trace "# sh( ...,  options: #{opts.to_s})"
        puts cmd unless opts.get :silent, false # log cmd verbatim
        begin
          res = IO.popen(cmd, 'r') { |io| io.readlines }
        rescue Errno::ENOENT => e
          return block.call(nil, $?)
        end
        puts res unless opts.get :silent, false
        return block.call($? == 0 && res, $?)
      end
    end
    
    # shell ignore exit code
    # returns:
    #  [ok, status]
    #  where status:
    #    #exitstatus : Int
    #    #pid      : Int
    def shie *cmd, &block
      block = lambda { |ok, status| [ok, status] } unless block_given?
      sh *cmd, &block
    end
    
    def which executable
      raise ArgumentError, "executable is nil" unless executable

      dir = File.dirname executable
      file = File.basename executable

      cmd = ::Rake::Win32.windows? ? 'where' : 'which'
      parameters = []
      parameters << Paths.normalize_slashes(file) if dir == '.'
      parameters << Paths.normalize_slashes("#{dir}:#{file}") unless dir == '.'

      trace "#{cmd} #{parameters.join(' ')}"

      # TODO: this still prints to STDERR on Windows
      res = IO.popen([cmd, *parameters]) do |io|
        io.read.chomp
      end
      
      unless $? == 0
        nil
      else
        res
      end
    rescue Errno::ENOENT => e
      trace "which/where returned #{$?}: #{e}"
      nil
    end
    
    def chdir wd, &block
      return block.call if wd.nil?
      Dir.chdir wd do
        trace "pushd #{wd}"
        res = block.call
        trace "popd #{wd}"
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
