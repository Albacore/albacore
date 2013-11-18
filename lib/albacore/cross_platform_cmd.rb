require 'rake'
require 'map'
require 'open3'
require 'timeout'
require 'processpilot/processpilot'
require 'albacore/paths'
require 'albacore/logging'
require 'albacore/errors/command_not_found_error'
require 'albacore/errors/command_failed_error'

# Exit status class for times the system just gives us a nil.
class Albacore::PseudoStatus
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

# A command class that can handle signal/pipe multiplexing and
# selecting in its child processes.
#
# More on the source - Foreman - Copyright (c) 2012 David Dollar at c3abaad3538a9bfc9a7cbe4bc815f2627acf3388:
# See https://github.com/ddollar/foreman/blob/master/lib/foreman/engine.rb
#
class Albacore::Command
  HANDLED_SIGNALS = [ :TERM, :INT, :HUP ]
  SIGNAL_QUEUE = []

  attr_reader :env
  attr_reader :options
  attr_reader :processes

  # initialise a new Albacore Command
  def initialize options = {}
    @options = options.dup
    @options[:timeout] ||= 5

    @env = {}
    @mutex = Mutex.new
    @names = {}
    @processes = []
    @running = {}
    @readers = {}

    # Self-pipe for deferred signal-handling (ala djb: http://cr.yp.to/docs/selfpipe.html)
    reader, writer = create_pipe
    reader.close_on_exec = true if reader.respond_to?(:close_on_exec)
    writer.close_on_exec = true if writer.respond_to?(:close_on_exec)
    @selfpipe = { :reader => reader, :writer => writer }

    # Set up a global signal queue
    # http://blog.rubybestpractices.com/posts/ewong/016-Implementing-Signal-Handlers.html
    Thread.main[:signal_queue] = []
  end


  # Start the processes registered to this +Engine+
  #
  def start
    register_signal_handlers
    startup
    spawn_processes
    watch_for_output
    sleep 0.1
    watch_for_termination { terminate_gracefully }
    shutdown
  end

  # Set up deferred signal handlers
  #
  def register_signal_handlers
    HANDLED_SIGNALS.each do |sig|
      if ::Signal.list.include? sig.to_s
        trap(sig) { Thread.main[:signal_queue] << sig ; notice_signal }
      end
    end
  end

  # Unregister deferred signal handlers
  #
  def restore_default_signal_handlers
    HANDLED_SIGNALS.each do |sig|
      trap(sig, :DEFAULT) if ::Signal.list.include? sig.to_s
    end
  end

  # Wake the main thread up via the selfpipe when there's a signal
  #
  def notice_signal
    @selfpipe[:writer].write_nonblock( '.' )
  rescue Errno::EAGAIN
    # Ignore writes that would block
  rescue Errno::EINT
    # Retry if another signal arrived while writing
    retry
  end

  # Invoke the real handler for signal +sig+. This shouldn't be called directly
  # by signal handlers, as it might invoke code which isn't re-entrant.
  #
  # @param [Symbol] sig the name of the signal to be handled
  #
  def handle_signal(sig)
    case sig
    when :TERM
      handle_term_signal
    when :INT
      handle_interrupt
    when :HUP
      handle_hangup
    else
      system "unhandled signal #{sig}"
    end
  end

  # Handle a TERM signal
  #
  def handle_term_signal
    puts "SIGTERM received"
    terminate_gracefully
  end

  # Handle an INT signal
  #
  def handle_interrupt
    puts "SIGINT received"
    terminate_gracefully
  end

  # Handle a HUP signal
  #
  def handle_hangup
    puts "SIGHUP received"
    terminate_gracefully
  end

  # Register a process to be run by this +Command+
  #
  # @param [String] name A name for this process
  # @param [String] command The command to run
  # @param [Hash] options
  #
  # @option options [Hash] :env A custom environment for this process
  #
  def register(name, command, options={})
    options[:env] ||= env
    options[:cwd] ||= File.dirname(command.split(" ").first)
    process = Foreman::Process.new(command, options)
    @names[process] = name
    @processes << process
  end

  # Clear the processes registered to this +Command+
  #
  def clear
    @names = {}
    @processes = []
  end

  # Send a signal to all processes started by this +Engine+
  #
  # @param [String] signal The signal to send to each process
  #
  def kill_children(signal="SIGTERM")
    if Albacore.windows?
      @running.each do |pid, (process, index)|
        system "sending #{signal} to #{name_for(pid)} at pid #{pid}"
        begin
          Process.kill(signal, pid)
        rescue Errno::ESRCH, Errno::EPERM
        end
      end
    else
      begin
        Process.kill signal, *@running.keys unless @running.empty?
      rescue Errno::ESRCH, Errno::EPERM
      end
    end
  end

  # Send a signal to the whole process group.
  #
  # @param [String] signal The signal to send
  #
  def killall(signal="SIGTERM")
    if Albacore.windows?
      kill_children(signal)
    else
      begin
        Process.kill "-#{signal}", Process.pid
      rescue Errno::ESRCH, Errno::EPERM
      end
    end
  end

  # Get the process formation
  #
  # @returns [Fixnum] The formation count for the specified process
  #
  def formation
    @formation ||= parse_formation(options[:formation])
  end

  # List the available process names
  #
  # @returns [Array] A list of process names
  #
  def process_names
    @processes.map { |p| @names[p] }
  end

  # Get the +Process+ for a specifid name
  #
  # @param [String] name The process name
  #
  # @returns [Foreman::Process] The +Process+ for the specified name
  #
  def process(name)
    @names.invert[name]
  end


  # Yield each +Process+ in order
  #
  def each_process
    process_names.each do |name|
      yield name, process(name)
    end
  end

  # Get the root directory for this +Engine+
  #
  # @returns [String] The root directory
  #
  def root
    File.expand_path(options[:root] || Dir.pwd)
  end


  def create_pipe
    IO.method(:pipe).arity.zero? ? IO.pipe : IO.pipe("BINARY")
  end

  def name_for(pid)
    process, index = @running[pid]
    name_for_index(process, index)
  end

  def name_for_index(process, index)
    [ @names[process], index.to_s ].compact.join(".")
  end

  def parse_formation(formation)
    pairs = formation.to_s.gsub(/\s/, "").split(",")

    pairs.inject(Hash.new(0)) do |ax, pair|
      process, amount = pair.split("=")
      process == "all" ? ax.default = amount.to_i : ax[process] = amount.to_i
      ax
    end
  end

  def output_with_mutex(name, message)
    @mutex.synchronize do
      output name, message
    end
  end

  def system(message)
    output_with_mutex "system", message
  end

  def termination_message_for(status)
    if status.exited?
      "exited with code #{status.exitstatus}"
    elsif status.signaled?
      "terminated by SIG#{Signal.list.invert[status.termsig]}"
    else
      "died a mysterious death"
    end
  end

  def flush_reader(reader)
    until reader.eof?
      data = reader.gets
      output_with_mutex name_for(@readers.key(reader)), data
    end
  end

## Engine ###########################################################

  def spawn_processes
    @processes.each do |process|
      1.upto(formation[@names[process]]) do |n|
        reader, writer = create_pipe
        begin
          pid = process.run(:output => writer, :env => {
            "PORT" => port_for(process, n).to_s,
            "PS" => name_for_index(process, n)
          })
          writer.puts "started with pid #{pid}"
        rescue Errno::ENOENT
          writer.puts "unknown command: #{process.command}"
        end
        @running[pid] = [process, n]
        @readers[pid] = reader
      end
    end
  end

  def watch_for_output
    Thread.new do
      begin
        loop do
          io = IO.select([@selfpipe[:reader]] + @readers.values, nil, nil, 30)

          begin
            @selfpipe[:reader].read_nonblock(11)
          rescue Errno::EAGAIN, Errno::EINTR => err
            # ignore
          end

          # Look for any signals that arrived and handle them
          while sig = Thread.main[:signal_queue].shift
            self.handle_signal(sig)
          end

          (io.nil? ? [] : io.first).each do |reader|
            next if reader == @selfpipe[:reader]

            if reader.eof?
              @readers.delete_if { |key, value| value == reader }
            else
              data = reader.gets
              output_with_mutex name_for(@readers.invert[reader]), data
            end
          end
        end
      rescue Exception => ex
        puts ex.message
        puts ex.backtrace
      end
    end
  end

  def watch_for_termination
    pid, status = Process.wait2
    output_with_mutex name_for(pid), termination_message_for(status)
    @running.delete(pid)
    yield if block_given?
    pid
  rescue Errno::ECHILD
  end

  def terminate_gracefully
    return if @terminating
    restore_default_signal_handlers
    @terminating = true
    if Foreman.windows?
      system "sending SIGKILL to all processes"
      kill_children "SIGKILL"
    else
      system "sending SIGTERM to all processes"
      kill_children "SIGTERM"
    end
    Timeout.timeout(options[:timeout]) do
      watch_for_termination while @running.length > 0
    end
  rescue Timeout::Error
    system "sending SIGKILL to all processes"
    kill_children "SIGKILL"
  end

  def execute

  end
end

# module for normalising slashes across operating systems
# and running commands
module Albacore::CrossPlatformCmd
  include Logging

    class << self
      include CrossPlatformCmd
    end

    attr_reader :pid

    KILL_TIMEOUT = 2 # seconds

    self_reader, self_writer = IO.pipe

    [:INT, :QUIT, :TERM].each do |signal|
      Signal.trap(signal) {
        # write a byte to the self-pipe
        self_writer.write_nonblock('.')
        SIGNAL_QUEUE << signal
      }
    end

    def initialize
      pid = Process.pid
      at_exit { stop if Process.pid == pid }
    end

    # run executable
    #
    # system(cmd, [args array], Hash(opts), block|ok,status|)
    #  ok => false if bad exit code, or the output otherwise
    # 
    # options are passed as the last argument
    #
    # options:
    #  work_dir: a file path (default '.')
    #  silent:   whether to supress all output or not (default false)
    #  output:   whether to supress the command's output (default false)
    #  out:      output pipe
    #  err:      error pipe
    #
    def system *cmd, &block
      raise ArgumentError, "cmd is nil" if cmd.nil? # don't allow nothing to be passed
      opts = Map.options((Hash === cmd.last) ? cmd.pop : {}). # same arg parsing as rake
        apply(
          silent: false,
          output: true,
          work_dir: FileUtils.pwd,
          out: Albacore.application.output,
          err: Albacore.application.output_err)

      exe, pars, printable, block = prepare_command cmd, &block

      out, err, inmem = opts.get(:out), opts.get(:err), StringIO.new

      trace { "system( exe=#{exe}, pars=[#{pars.join(', ')}], options=#{opts.to_s}), in directory: #{opts.getopt(:workdir, '<<current>>')} [cross_platform_cmd #system]" }

      Thread.new do
        begin
          
        rescue Exception => e
          err.puts ex.message
          err.puts ex.backtrace
        end
      end


      puts printable unless opts.get :silent, false # log cmd verbatim

      handle_not_found block do
        # create a pipe for the process to work with
        read, write = IO.pipe
        eread, ewrite = IO.pipe

        # this thread chews through the output
        @out_thread = Thread.new {
          
          while !read.eof?
            data = read.readpartial(1024)
            out.write data
            inmem.write data # to give the block at the end
          end
        }

        debug 'execute the new process, letting it write to the write FD (file descriptor)'
        @pid = Process.spawn(*[exe, *pars],
          out:   write,
          err:   ewrite,
          chdir: opts.get(:work_dir))

        debug 'waiting for process completion'
        _, status = Process.wait2 @pid

        #debug 'waiting for thread completion'
        #@out_thread.join

        return block.call(status.success? && inmem.string, status)
      end
    end  

    def stop
      if pid
        begin
          Process.kill('TERM', pid)

          begin
            Timeout.timeout(KILL_TIMEOUT) { Process.wait(pid) }
          rescue Timeout::Error
            Process.kill('KILL', pid)
            Process.wait(pid)
          end
        rescue Errno::ESRCH, Errno::ECHILD
          # Zed's dead, baby
        end

        @out_thread.kill
        @pid = nil
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

        trace { "#sh( ...,  options: #{opts.to_s}) [cross_platform_cmd #sh]" }
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

    def normalise_slashes path
      ::Albacore::Paths.normalise_slashes path
    end

    # create a new command string
    def make_command
      ::Albacore::Paths.make_command @executable, @parameters
    end

    def which executable
      raise ArgumentError, "executable is nil" unless executable

      dir = File.dirname executable
      file = File.basename executable

      cmd = Albacore.windows? ? 'where' : 'which'
      parameters = []
      parameters << Paths.normalise_slashes(file) if dir == '.'
      parameters << Paths.normalise_slashes("#{dir}:#{file}") unless dir == '.'
      cmd, parameters = Paths.normalise cmd, parameters

      trace { "#{cmd} #{parameters.join(' ')} [cross_platform_cmd #which]" }

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
      trace "which/where returned #{$?}: #{e} [cross_platform_cmd #which]"
      nil
    end
    
    def chdir wd, &block
      return block.call if wd.nil?
      Dir.chdir wd do
        debug { "pushd #{wd} [cross_platform_cmd #chdir]" }
        res = block.call
        debug { "popd #{wd} [cross_platform_cmd #chdir]" }
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
