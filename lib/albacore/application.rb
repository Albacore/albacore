require 'rake'
module Albacore
  class Application
		def define_task *args, &block
			Rake::Task.define_task *args, &block
		end
  end
end
