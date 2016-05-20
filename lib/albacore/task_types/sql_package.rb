# encoding: utf-8

require 'rake'
require 'albacore/paths'
require 'albacore/cmd_config'
require 'albacore/cross_platform_cmd'
require 'albacore/logging'
require 'albacore/facts'

module Albacore
  module SqlPackage
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

    # The configuration class for SqlPackage. MSDN docs at: https://msdn.microsoft.com/en-us/library/hh550080(vs.103).aspx
    class Config
      include CmdConfig
      self.extend ConfigDSL
      include Logging

      # TODO: move towards #opts() for all task types rather than
      # reading these public properties.

      # this is the action of SqlPackage
      attr_reader :action

      # this is the source of SqlPackage
      attr_reader :source

      # this is the profile of SqlPackage
      attr_reader :profile

      # any properties you want to set
      attr_accessor :properties

      def initialize
        @parameters = Set.new

        w = lambda { |e| CrossPlatformCmd.which(e) ? e : nil }

        @exe = w.call( "SqlPackage" ) 

        debug { "SqlPackage using '#{@exe}'" }

      end

      # Allows you to add properties to MsBuild; example:
      #
      # b.prop 'CommandTimeout', 60
      # b.prop 'DacMajorVersion', 1
      #
      # The properties will be automatically converted to the correct syntax
      def prop k, v
        @properties ||= Hash.new
        @parameters.delete "/p:#{make_props}" if @properties.any?
        @properties[k] = v
        @parameters.add "/p:#{make_props}"
      end

      # Specifies the action to be performed.
      attr_path_accessor :action do |a|
        set_action a
      end

      # Specifies whether checks should be performed before publishing that will stop the 
      # publish action if issues are present that might block successful publishing. 
      # For example, your publish action might stop if you have foreign keys on the 
      # target database that do not exist in the database project, and that will 
      # cause errors when you publish.
      attr_path_accessor :verify_deployment do |bool|
        @parameters.add "/p:VerifyDeployment:#{bool}"
      end

      # Specifies whether detailed feedback is suppressed. Defaults to False.
      attr_path_accessor :be_quiet do |q|
        @parameters.add "/Quiet:#{q}"
      end

      # Specifies a source file to be used as the source of action instead of database. 
      # If this parameter is used, no other source parameter shall be valid.
      attr_path_accessor :source do |s|
        @parameters.add "/SourceFile:#{s}"
      end

      # Specifies the file path to a DAC Publish Profile. The profile defines a 
      # collection of properties and variables to use when generating outputs.
      attr_path_accessor :profile do |p|
        @parameters.add "/Profile:#{p}"
      end

      private
      def set_action action
        actions = %w{Extract DeployReport DriftReport Publish Script Export Import Pipe}.collect{ |a| "/Action:#{a}" }
        @parameters.subtract actions
        @parameters.add "/Action:#{action}"
      end

      def make_props
        @properties.collect { |k, v|
          "#{k}=#{v}"
        }.join(';')
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
