class CsProjFiles
  attr_accessor :failed, :failure_message
  
  def fail_with_message(msg)
    @failed = true
    @failure_message = msg
  end
end