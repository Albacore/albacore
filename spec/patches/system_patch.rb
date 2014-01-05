module SystemPatch    
  attr_accessor :system_command
  
  def system(cmd)
    @system_command = cmd
    return true
  end
end
