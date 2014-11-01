module ShInterceptor

  # for sh, and system with arguments turned into a string
  attr_accessor :received

  # for #system
  attr_accessor :executable

  # for #system
  attr_accessor :parameters

  # for #system
  attr_accessor :options

  def is_mono_command? index = 0
    e = invocations[index].executable
    e.downcase == 'mono'
  end

  # gets the command (which might be mono-prefixed), without
  # the mono-prefix.
  def mono_command index = 0
    invocation = invocations[index]
    fail "no invocation with index = #{index}" unless invocation
    parameters = invocation.parameters
    is_mono_command?(index) ?
      parameters[0] :
      executable
  end

  def mono_parameters index = 0
    invocation = invocations[index]
    fail "no invocation with index = #{index}" unless invocation
    parameters = invocation.parameters
    is_mono_command?(index) ?
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

  # intercepts #system
  def system *args
    @options = (Hash === args.last) ? args.pop : {}
    @executable = args[0] || ''
    @parameters = args[1..-1].flatten || []
    @system_calls = system_calls + 1
    add_invocation(OpenStruct.new({ :executable => @executable, :parameters => @parameters, :options => @options }))
    "".force_encoding 'utf-8' # expecting string output in utf-8 (hopefully)
  end

  # gets the invocations given to #system, with readers:
  # + executable : string
  # + parameters : 'a array
  # + options    : Hash
  def invocations
    @invocations || []
  end

  private
  def add_invocation invocation
    Albacore.application.logger.debug "adding invocation: #{invocation}"
    @invocations = (@invocations || [])
    @invocations << invocation
  end

  # intercepts #sh
  def sh *args
    @received = args
  end

  # intercepts #shie
  def shie *args
    @received = args
  end

end

