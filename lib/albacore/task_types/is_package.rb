# encoding: utf-8

require 'rake'
require 'albacore/paths'
require 'albacore/cmd_config'
require 'albacore/cross_platform_cmd'
require 'albacore/logging'
require 'albacore/facts'

module Albacore
  module IsPackage
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

    # The configuration class for ISDeploymentWizard. MSDN docs at: https://msdn.microsoft.com/en-gb/library/hh213373.aspx
    class Config
      include CmdConfig
      self.extend ConfigDSL
      include Logging

      # this is the is_package of ISDeploymentWizard
      attr_reader :is_package

      # this is the server of ISDeploymentWizard
      attr_reader :server

      # this is the database of ISDeploymentWizard
      attr_accessor :database

      # this is the folder_name of ISDeploymentWizard
      attr_accessor :folder_name

     # this is the project_name of ISDeploymentWizard
      attr_accessor :project_name


      def initialize
        @parameters = Set.new

        w = lambda { |e| CrossPlatformCmd.which(e) ? e : nil }

        @exe = w.call( "ISDeploymentWizard" ) 

        debug { "ISDeploymentWizard using '#{@exe}'" }
      end

      def be_quiet
        @parameters.add "/Silent"
      end

      attr_path_accessor :is_package do |s|
        @parameters.add "/SourcePath:#{s}"
      end

      attr_path_accessor :server do |ds|
        @parameters.add "/DestinationServer:#{ds}"
      end

      def get_parameters
        make_folder
        @parameters
      end

      private

      def make_folder
        @parameters.add "/DestinationPath:/#{database}/#{folder_name}/#{project_name}"
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
