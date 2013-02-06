module ShInterceptor
  def sh wd, *args
    @wd = wd
    @received = args
  end
  def shie wd, *args
    @wd = wd
    @received = args
  end
  def system_calls
    @system_control_calls || 0
  end
  def system *args, &block
    @received = args[0]
    @system_calls = system_calls + 1
  end
  def system_control_calls
    @system_control_calls || 0
  end
  def system_control cmd, *args, &block
    @wd = Map.options(args).getopt(:work_dir)
    @received = cmd
    @args = args
    @system_control_calls = system_control_calls + 1
  end
  def received_wd
    @wd || nil
  end
  def received_args
     return @received if @received.respond_to? :zip
     return [@received] if @received.instance_of?(String)
     [] 
  end
end

