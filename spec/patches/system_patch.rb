module SystemPatch    
  attr_accessor :system_command
  
  def system(cmd)
    @system_command = cmd
    return !@fail
  end

  def force_failure
    @fail = true
  end
end
