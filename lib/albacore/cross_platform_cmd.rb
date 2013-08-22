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
      opts = Map.options((Hash === cmd.last) ? cmd.pop : {}). # same arg parsing as rake
        apply(
          silent: false,
          output: true,
          out: Albacore.application.output,
          err: Albacore.application.output_err)

      exe, pars, printable, block = prepare_command cmd, &block

      # TODO: figure out how to interleave output and error streams
      out, _, inmem = opts.get(:out), opts.get(:err), StringIO.new

      trace "system( exe=#{exe}, pars=[#{pars.join(', ')}], options=#{opts.to_s}), in directory: #{opts.getopt(:workdir, '<<current>>')}"

      puts printable unless opts.get :silent, false # log cmd verbatim

      handle_not_found block do
        # create a pipe for the process to work with
        read, write = IO.pipe

        # this thread chews through the output
        out_thread = Thread.new {
          while !read.eof? && data = read.readpartial(1024)
            out.write data
            inmem.write data # to give the block at the end
          end
        }

        # execute the new process, letting it write to the write FD (file descriptor)
        pid = Process.spawn(*[exe, *pars], out: write, chdir: opts.getopt(:workdir, FileUtils.pwd))

        # wait for completion
        _, status = Process.wait2 pid

        return block.call(status.success? && inmem.string, status)
      end
    end

    # http://www.ruby-doc.org/core-2.0/Process.html#method-c-spawn
    # https://practicingruby.com/articles/shared/ujxrxprnlugz
    # https://github.com/jonleighton/poltergeist/blob/3365dadfb6242b0b91fe00359ff881e582cc2557/lib/capybara/poltergeist/client.rb

    # run in shell
    def sh *cmd, &block
      raise ArgumentError, "cmd is nil" if cmd.nil? # don't allow nothing to be passed
      opts = Map.options((Hash === cmd.last) ? cmd.pop : {}) # same arg parsing as rake

      cmd = cmd.join(' ') # shell needs a single string
      block = handler_with_message cmd unless block_given?

      chdir opts.get(:work_dir) do

        trace "# sh( ...,  options: #{opts.to_s})"
        puts cmd unless opts.getopt :silent, false # log cmd verbatim

        lines = ''
        handle_not_found block do
          IO.popen(cmd, 'r') do |io|
            io.each do |line|
              lines << line
              puts line if opts.getopt(:output, true) or not opts.getopt(:silent, false)
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
      block = lambda { |ok, status| ok } unless block_given?
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
        debug "pushd #{wd}"
        res = block.call
        debug "popd #{wd}"
        return res
      end
    end
    
    private

    def prepare_command cmd, &block
      pars = cmd[1..-1].flatten
      raise ArgumentError, "arguments 1..-1 must be an array" unless pars.is_a? Array

      exe, pars = ::Albacore::Paths.normalise cmd[0], pars 
      printable = %Q{#{exe} #{pars.join(' ')}}
      handler = block_given? ? block : handler_with_message(printable)
      [exe, pars, printable, handler]
    end

    def handler_with_message printable
      lambda { |ok, status| ok or raise_failure(printable, status) }
    end

    # handles the errors from not finding the executable on the system
    def handle_not_found rescue_block
      yield
    rescue Errno::ENOENT => e
      rescue_block.call(nil, PseudoStatus.new(127))
    rescue IOError => e # rescue for JRuby
      rescue_block.call(nil, PseudoStatus.new(127)) 
    end


    def knowns
      { 127 => 'number 127 in particular means that the operating system could not find the executable' }
    end

    def raise_failure cmd, status
      if status.exitstatus == 127
        raise CommandNotFoundError.new(format_failure(cmd, status), cmd)
      else
        raise CommandFailedError.new(format_failure(cmd, status), cmd)
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
