require 'albacore/albacoretask'
require 'albacore/config/msbuildconfig.rb'

class MSBuild
  include Albacore::Task
  include Albacore::RunCommand
  include Configuration::MSBuild

  attr_accessor :solution, :verbosity, :loggermodule, :max_cpu_count
  attr_array :targets
  attr_hash :properties, :other_switches

  def initialize
    super()
    update_attributes msbuild.to_hash
  end

  def execute
    build_solution(@solution)
  end

  def nologo
    @nologo = true
  end

  def build_solution(solution)
    check_solution solution

    command_parameters = []
    command_parameters << "\"#{solution}\""
    command_parameters << "\"/verbosity:#{@verbosity}\"" unless @verbosity.nil?
    command_parameters << "\"/logger:#{@loggermodule}\"" unless @loggermodule.nil?
    command_parameters << "\"/maxcpucount:#{@max_cpu_count}\"" unless @max_cpu_count.nil?
    command_parameters << "\"/nologo\"" if @nologo
    command_parameters << build_properties unless @properties.nil?
    command_parameters << build_switches unless @other_switches.nil?
    command_parameters << "\"/target:#{build_targets}\"" unless @targets.nil?

    result = run_command ["MSBuild", "XBuild"], command_parameters

    failure_message = 'MSBuild Failed. See Build Log For Detail'
    fail_with_message failure_message if !result
  end

  def check_solution(file)
    return if file
    msg = 'solution cannot be nil'
    fail_with_message msg
  end

  def build_targets
    @targets.join ";"
  end

  def build_properties
    option_text = []
    @properties.each do |key, value|
      option_text << "/p:#{key}\=\"#{value}\""
    end
    option_text.join(" ")
  end

  def build_switches
    switch_text = []
    @other_switches.each do |key, value|
      switch_text << print_switch(key, value)
    end
    switch_text.join(" ")
  end

  def print_switch(key, value)
    pure_switch?(value) ? "/#{key}" : "/#{key}:\"#{value}\""
  end

  def pure_switch?(value)
    value.is_a?(TrueClass) || value == :true
  end
end
