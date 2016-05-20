# encoding: utf-8

require 'rake'
require 'albacore/paths'
require 'albacore/cmd_config'
require 'albacore/cross_platform_cmd'
require 'albacore/logging'
require 'albacore/facts'

module Albacore
  module Sql
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

    # The configuration class for SqlCmd. MSDN docs at: https://msdn.microsoft.com/en-us/library/ms162773.aspx
    class Config
      include CmdConfig
      self.extend ConfigDSL
      include Logging

      # this is the server for SqlCmd
      attr_writer :server

      # this is the database for SqlCmd
      attr_writer :database

      # this is the username for SqlCmd
      attr_writer :username

      # this is the password for SqlCmd
      attr_writer :password

      # this is the scripts for SqlCmd
      attr_writer :scripts

      def initialize
        @parameters = Set.new

        w = lambda { |e| CrossPlatformCmd.which(e) ? e : nil }

        @exe = w.call( "SqlCmd" ) 

        debug { "SqlCmd using '#{@exe}'" }

      end

      def trusted_connection
        @parameters.add('-E')
      end

      attr_path_accessor :server do |s|
        @parameters.add("-S#{s}")
      end

      attr_path_accessor :database do |d|
        @parameters.add("-d#{d}")
      end      

      attr_path_accessor :username do |u|
        @parameters.add("-U#{u}")
        @parameters.delete('-E')
      end

      attr_path_accessor :password do |p|
        @parameters.add("-P#{p}")
        @parameters.delete('-E')
      end

      # gets the options specified for the task, used from the task
      def opts

        Map.new({
          :exe      => @exe,
          :parameters => @parameters,
          :scripts  => @scripts,
          :original_path => FileUtils.pwd
        })
      end

    end

     # a task that handles the execution of sql scripts.
    class SqlTask
      include Logging

      def initialize work_dir, opts
        raise ArgumentError, 'opts is not a map' unless opts.is_a? Map
        raise ArgumentError, 'no scripts given' unless opts.get(:scripts).length > 0
        raise ArgumentError, 'no parameters given' unless opts.get(:parameters).length > 0

        @opts = opts.apply :work_dir => work_dir
        @scripts = opts.get :scripts
      end

      def execute
        @scripts.each do |s|
          execute_inner! @opts.get(:work_dir), s
        end
      end
      
      # execute, for each sql script
      def execute_inner! work_dir, script

        exe = path_to(@opts.get(:exe), work_dir)
        parameters = @opts.get(:parameters)
        parameters.add("-i#{script.gsub('/','\\')}")
        
        cmd = Albacore::Sql::Cmd.new(work_dir, exe, parameters)

        cmd.execute

        fail "SqlCmd.exe is not installed.\nPlease download and install Microsoft SQL Server 2012 Command Line Utilities: https://www.microsoft.com/en-gb/download/confirmation.aspx?id=29065\nAnd add the location of SqlCmd.exe to the PATH system varible." unless exe

      end

      def path_to path, work_dir
        if (Pathname.new path).absolute?
           return path
        else
           return File.expand_path( File.join(@opts.get(:original_path), path), work_dir )
        end
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