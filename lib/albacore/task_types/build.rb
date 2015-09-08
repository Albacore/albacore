# encoding: utf-8

require 'rake'
require 'albacore/paths'
require 'albacore/cmd_config'
require 'albacore/cross_platform_cmd'
require 'albacore/logging'
require 'albacore/facts'
require 'albacore/task_types/find_msbuild_versions'

module Albacore
  module Build
    class Cmd
      include CrossPlatformCmd
      def initialize work_dir, executable, parameters
        @work_dir = work_dir
        @executable = executable
        @parameters = (parameters === Array) ? parameters : parameters.to_a
      end
      def execute
        system @executable, @parameters, :work_dir => @work_dir
      end
    end

    # The configuration class for xbuild and msbuild. MSDN docs at: http://msdn.microsoft.com/en-us/library/vstudio/ms164311.aspx
    class Config
      include CmdConfig
      self.extend ConfigDSL
      include Logging

      # TODO: move towards #opts() for all task types rather than
      # reading these public properties.

      # this is the target of the compilation with MsBuild/XBuild
      attr_reader :target

      # any properties you want to set
      attr_accessor :properties

      def initialize
        @parameters = Set.new

        w = lambda { |e| CrossPlatformCmd.which(e) ? e : nil }

        @exe = w.call( "msbuild" ) ||
               w.call( "xbuild" )  ||
               heuristic_executable

        debug { "build using '#{@exe}'" }
        set_logging (ENV['DEBUG'] ?
                      (ENV['VERBOSE'] ?
                        'detailed' :
                        'normal') :
                      'minimal')
      end

      # this is the solution file to build (or the project files themselves)
      attr_path_accessor :sln, :file do |val|
        @parameters.add val
      end

      # Call for each target that you want to add, or pass an array or
      # strings. Only unique targets will be passed to MsBuild.
      #
      # From MSDN:
      #
      # "Build the specified targets in the project. Specify each target separately, or use a semicolon or comma to separate multiple targets, as the following example shows:
      # /target:Resources;Compile
      # If you specify any targets by using this switch, they are run instead of any targets in the DefaultTargets attribute in the project file. For more information, see Target Build Order (http://msdn.microsoft.com/en-us/library/vstudio/ee216359.aspx) and How to: Specify Which Target to Build First (http://msdn.microsoft.com/en-us/library/vstudio/ms171463.aspx).
      # A target is a group of tasks. For more information, see MSBuild Targets (http://msdn.microsoft.com/en-us/library/vstudio/ms171462.aspx)."
      #
      # t  :: the array or string target to add to the list of targets to build
      attr_path_accessor :target do |t|
        update_array_prop "target", method(:make_target), :targets, t
      end

      # Allows you to add properties to MsBuild; example:
      #
      # b.prop 'WarningLevel', 2
      # b.prop 'BuildVersion', '3.5.0'
      #
      # From MSDN:
      #
      # "Set or override the specified project-level properties, where name is the property name and value is the property value. Specify each property separately, or use a semicolon or comma to separate multiple properties, as the following example shows:
      # /property:WarningLevel=2;OutputDir=bin\Debug"
      #
      # The properties will be automatically converted to the correct syntax
      def prop k, v
        @properties ||= Hash.new
        @parameters.delete "/property:#{make_props}" if @properties.any?
        @properties[k] = v
        @parameters.add "/property:#{make_props}"
      end

      # Specifies the amount of information to display in the build log.
      # Each logger displays events based on the verbosity level that you set for that logger.
      # You can specify the following verbosity levels: q[uiet], m[inimal],
      # n[ormal], d[etailed], and diag[nostic].
      attr_path_accessor :logging do |mode|
        set_logging mode
      end


      #  Gets or sets a target .NET Framework version to build the project with, which
      #  enables an MSBuild task to build a project that targets a different version of
      #  the .NET Framework than the one specified in the project. Valid values are 2.0,
      #  3.0 and 3.5.
      #
      attr_path_accessor :tools_version do |t|
        @parameters.add "/toolsversion:#{t}"
      end

      # Specifies the number of parallel worker processes to build with
      # Defaults to the number of logical cores
      attr_path_accessor :cores do |num|
        @parameters.add "/maxcpucount:#{num}"
      end

      # Pass the parameters that you specify to the console logger, which displays build information in the console window. You can specify the following parameters:
      # * PerformanceSummary. Show the time that's spent in tasks, targets and projects.
      # * Summary. Show the error and warning summary at the end.
      # * NoSummary. Don't show the error and warning summary at the end.
      # * ErrorsOnly. Show only errors.
      # * WarningsOnly. Show only warnings.
      # * NoItemAndPropertyList. Don't show the list of items and properties that would appear at the start of each project build if the verbosity level is set to diagnostic.
      # * ShowCommandLine. Show TaskCommandLineEvent messages.
      # * ShowTimestamp. Show the timestamp as a prefix to any message.
      # * ShowEventId. Show the event ID for each started event, finished event, and message.
      # * ForceNoAlign. Don't align the text to the size of the console buffer.
      # * DisableConsoleColor. Use the default console colors for all logging messages.
      # * DisableMPLogging. Disable the multiprocessor logging style of output when running in non-multiprocessor mode.
      # * EnableMPLogging. Enable the multiprocessor logging style even when running in non-multiprocessor mode. This logging style is on by default.
      # * Verbosity. Override the /verbosity setting for this logger.
      def clp param
        update_array_prop "consoleloggerparameters", method(:make_clp), :clp, param
      end

      # Set logging verbosity to quiet
      def be_quiet
        logging = "quiet"
      end

      # Don't display the startup banner or the copyright message.
      def nologo
        @parameters.add "/nologo"
      end

      private
      def set_logging mode
        modes = %w{quiet minimal normal detailed diagnostic}.collect{ |m| "/verbosity:#{m}" }
        @parameters.subtract modes
        @parameters.add "/verbosity:#{mode}"
      end

      def update_array_prop prop_name, callable_prop_val, field_sym, value
        field = :"@#{field_sym}"
        # @targets ||= []
        instance_variable_set field, [] unless instance_variable_defined? field
        # parameters.delete "/target:#{make_target}" if @targets.any?
        @parameters.delete "/#{prop_name}:#{callable_prop_val.call}" if
          instance_variable_get(field).any?
        if value.respond_to? 'each'
          value.each { |v| instance_variable_get(field) << v }
        else
          instance_variable_get(field) << value
        end
        instance_variable_get(field).uniq!
        # @parameters.add "/target:#{make_target}"
        @parameters.add "/#{prop_name}:#{callable_prop_val.call}"
      end

      def make_target
        @targets.join(';')
      end

      def make_props
        @properties.collect { |k, v|
          "#{k}=#{v}"
        }.join(';')
      end

      def make_clp
        @clp.join(';')
      end

      def heuristic_executable
    	  return nil unless ::Rake::Win32.windows?
    	  require 'win32/registry'
    	  trace 'build tasktype finding msbuild.exe'

    	  msb = "msbuild_not_found"
    	  maxVersion = -1
        versions = Albacore.find_msbuild_versions
        if versions.any?
          msb = versions.max[1]
        end
    	  CrossPlatformCmd.which(msb) ? msb : nil
      end

    end
    class Task
      def initialize command_line
        @command_line = command_line
      end
      def execute
        @command_line.execute
      end
    end
  end
end
