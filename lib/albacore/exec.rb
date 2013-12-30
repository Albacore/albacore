require "albacore/albacoretask"
require "albacore/config/execconfig"

class Exec
  TaskName = :exec

  include Albacore::Task
  include Albacore::RunCommand
  include Configuration::Exec

  def initialize
    super()
    update_attributes(exec.to_hash)
  end
    
  def execute
    result = run_command("Exec")
    fail_with_message("Exec failed, see the build log for more details.") unless result
  end
end
