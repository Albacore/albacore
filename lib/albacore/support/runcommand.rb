require 'albacore/support/attrmethods'

module Albacore
  module RunCommand
    extend AttrMethods

    attr_accessor :command, :working_directory
    attr_array :parameters

    def initialize command = nil, parameters = [], working_directory = Dir.pwd
      @working_directory = working_directory
      @parameters = parameters || []
      @command = command unless command.nil?
      super()
    end

    def run_command name="TaskName", parameters=[]
      raise(ArgumentError, "Don't pass nil as parameters.") if parameters.nil?
      params = parameters
      params << @parameters unless @parameters.empty?

      begin
        Dir.chdir(@working_directory) do
          cmd = get_command params
          @logger.debug "Executing #{name}: #{cmd}"
          return system cmd
        end

      rescue Exception => e
        puts "Error While Running Command Line Tool: #{e}"
        raise
      end
    end

    def get_command params
      executable = @command
      unless command.nil?
        executable = File.expand_path(@command) if File.exists?(@command)
      end

      if params.length > 0
        %{"#{executable}" #{params.join(' ')}}
      else
        %{"#{executable}"}
      end
    end
  end
end
