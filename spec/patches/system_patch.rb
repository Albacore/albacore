module SystemPatch
  attr_accessor :disable_system, :force_system_failure
  
  def system_command
    @system_command
  end
 
  def system cmd
    @disable_system ||= true
    @force_command_failure ||= false
    @system_command = cmd
    result = true
    result = super(cmd) unless disable_system
    return false if force_system_failure
    return result
  end
end
