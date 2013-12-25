require "albacore/albacoretask"

class Exec
  TaskName = :exec

  include Albacore::Task
  include Albacore::RunCommand

  def initialize
    super()
    update_attributes(Albacore.configuration.exec.to_hash)
  end
    
  def execute
    result = run_command("Exec")
    fail_with_message("Exec failed, see the build log for more details.") unless result
  end
end
