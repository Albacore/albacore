require 'rake'
require 'map'
require 'processpilot/processpilot'
require 'albacore/paths'
require 'albacore/logging'
require 'albacore/errors/command_not_found_error'
require 'open3'

module Albacore
  # module for normalising slashes across operating systems
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

    def normalise_slashes path
      ::Albacore::Paths.normalise_slashes path
    end

    # create
    def make_command
      ::Albacore::Paths.make_command @executable, @parameters
    end

    # run executable
    #
    # system(cmd, [args array], Hash(opts), block|ok,status|)
    #  ok => false if bad exit code, or the output otherwise
    # 
    # options are passed as the last argument
    #
    # options:
    #  :work_dir => a file path (default '.')
    #  :silent   => whether to supress all output or not (default false)
    #  :output   => whether to supress the command's output (default false)
    #
    def system *cmd, &block
      raise ArgumentError, "cmd is nil" if cmd.nil? # don't allow nothing to be passed

      opts = Map.options((Hash === cmd.last) ? cmd.pop : {}) # same arg parsing as rake
      pars = cmd[1..-1].flatten

      raise ArgumentError, "arguments 1..-1 must be an array" unless pars.is_a? Array

      exe, pars = ::Albacore::Paths.normalise cmd[0], pars 
      printable = %Q{#{exe} #{pars.join(' ')}}
      block = lambda { |ok, status| ok or raise_failure(printable, status) } unless block_given?

      trace "system( exe=#{exe}, pars=[#{pars.join(', ')}], options=#{opts.to_s})"

      chdir opts.get(:work_dir) do
        puts printable unless opts.get :silent, false # log cmd verbatim
        lines = ''
        handle_not_found block do
          IO.popen([exe, *pars], spawn_opts(opts)) do |io| # when given a block, returns #IO
            io.each do |line|
              lines << line
              puts line if opts.get(:output, true) or not opts.get(:silent, false)
            end
          end
        end
        return block.call($? == 0 && lines, $?)
      end
    end

    # gets the spawn options based on a #Map input for a #system or #sh or #shie call.
    # see http://www.ruby-doc.org/core-1.9.3/Process.html#method-c-spawn
    # only handles err and out so far
    def spawn_opts call_opts
      opts = {}
      opts[:err] = Albacore.application.output_err unless call_opts.get :silent, false
      opts[:out] = Albacore.application.output if call_opts.get :output, true
      opts
    end

    # run in shell
    def sh *cmd, &block
      raise ArgumentError, "cmd is nil" if cmd.nil? # don't allow nothing to be passed
      opts = Map.options((Hash === cmd.last) ? cmd.pop : {}) # same arg parsing as rake

      cmd = cmd.join(' ') # shell needs a single string
      block = lambda { |ok, status| ok or format_failure(cmd, status) } unless block_given?

      chdir opts.get(:work_dir) do

        trace "# sh( ...,  options: #{opts.to_s})"
        puts cmd unless opts.get :silent, false # log cmd verbatim

        lines = ''
        handle_not_found block do
          IO.popen(cmd, 'r') do |io|
            io.each do |line|
              lines << line
              puts line if opts.get(:output, true) or not opts.get(:silent, false)
            end
          end
        end

        return block.call($? == 0 && lines, $?)
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
    
    def system_control cmd, *opts, &block
      cmd = opts[0]
      opts = Map.options((Hash === cmd.last) ? cmd.pop : {}) # same arg parsing as rake
      chdir opts[:work_dir] do
        puts cmd
        ProcessPilot::pilot cmd, opts, &block
      end
    end
    
    def which executable
      raise ArgumentError, "executable is nil" unless executable

      dir = File.dirname executable
      file = File.basename executable

      cmd = ::Rake::Win32.windows? ? 'where' : 'which'
      parameters = []
      parameters << Paths.normalise_slashes(file) if dir == '.'
      parameters << Paths.normalise_slashes("#{dir}:#{file}") unless dir == '.'
      cmd, parameters = Paths.normalise cmd, parameters

      trace "#{cmd} #{parameters.join(' ')}"

      null = ::Rake::Win32.windows? ? "NUL" : "/dev/null"
      res = IO.popen([cmd, *parameters], { :err => null, :out => null }) do |io|
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
        debug "pushd #{wd}"
        res = block.call
        debug "popd #{wd}"
        return res
      end
    end
    
    private

    # handles the errors from not finding the executable on the system
    def handle_not_found rescue_block
      yield
    rescue Errno::ENOENT => e
      return rescue_block.call(nil, PseudoStatus.new(127))
    rescue IOError => e # rescue for JRuby
      return rescue_block.call(nil, PseudoStatus.new(127)) 
    end


    def knowns
      { 127 => 'number 127 in particular means that the operating system could not find the executable' }
    end

    def raise_failure cmd, status
      if status.exitstatus == 127
        raise CommandNotFoundError.new(format_failure(cmd, status), cmd)
      else
        fail(format_failure(cmd, status))
      end
    end

    def format_failure cmd, status
      if knowns.has_key? status.exitstatus
        %{Command failed with status (#{status.exitstatus}) - #{knowns[status.exitstatus]}:
  #{cmd}}
      else
        %{Command failed with status (#{status.exitstatus}):
  #{cmd}}
      end 
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
