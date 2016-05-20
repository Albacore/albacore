# encoding: utf-8

require 'rake'
require 'albacore/paths'
require 'albacore/cmd_config'
require 'albacore/cross_platform_cmd'
require 'albacore/logging'
require 'albacore/facts'

module Albacore
  module IsDeploy
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

      # this is the source_path of ISDeploymentWizard
      attr_reader :source_path

      # this is the destination_server of ISDeploymentWizard
      attr_reader :destination_server

      # this is the destination_database of ISDeploymentWizard
      attr_accessor :destination_database

      # this is the destination_folder_name of ISDeploymentWizard
      attr_accessor :destination_folder_name

     # this is the destination_project_name of ISDeploymentWizard
      attr_accessor :destination_project_name


      def initialize
        @parameters = Set.new

        w = lambda { |e| CrossPlatformCmd.which(e) ? e : nil }

        @exe = w.call( "ISDeploymentWizard" ) 

        debug { "ISDeploymentWizard using '#{@exe}'" }
      end

      def be_quiet
        @parameters.add "/Silent"
      end

      attr_path_accessor :source_path do |s|
        @parameters.add "/SourcePath:#{s}"
      end

      attr_path_accessor :destination_server do |ds|
        @parameters.add "/DestinationServer:#{ds}"
      end

      def get_parameters
        make_destination_folder
        @parameters
      end

      private

      def make_destination_folder
        @parameters.add "/DestinationPath:/#{destination_database}/#{destination_folder_name}/#{destination_project_name}"
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
