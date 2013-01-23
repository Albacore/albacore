require 'albacore/asmver'
require 'albacore/cross_platform_cmd'

module Albacore
  module DSL
    include Albacore::CrossPlatformCmd
    
    private

    
    # a rake task type for outputting assembly versions
    def asmver *args, &block
      args ||= []
      c = Albacore::AsmVer::Config.new
      yield c if block_given?
      
      body = proc {
        c.projects.each { |p|
          cmd = Albacore::AsmVer::Cmd.new p
          Albacore::AsmVer::Task.new(cmd).execute
        }
      }
      
      Rake::Task.define_task *args, &body
    end
  end
end

self.extend Albacore::DSL