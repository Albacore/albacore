module ShInterceptor

  # for sh, and system with arguments turned into a string
  attr_accessor :received

  # for #system
  attr_accessor :executable

  # for #system
  attr_accessor :parameters

  # for #system
  attr_accessor :options

  def is_mono_command?
    executable.downcase == 'mono'
  end

  # gets the command (which might be mono-prefixed), without
  # the mono-prefix.
  def mono_command
    is_mono_command? ?
      parameters[0] :
      executable
  end

  def mono_parameters
    is_mono_command? ?
      parameters[1..-1] :
      parameters
  end

  def system_calls
    if @system_calls.nil?
      0
    else
      @system_calls
    end
  end

  def received_args
    fail 'fix here'
    @parameters
  end

  def options
    @options
  end

  # intercepts #sh
  def sh *args
    @received = args
  end

  # intercepts #shie
  def shie *args
    @received = args
  end

  # intercepts #system
  def system *args
    @options = (Hash === args.last) ? args.pop : {}
    @executable = args[0] || ''
    @parameters = args[1..-1].flatten || []
    @system_calls = system_calls + 1
  end
end

