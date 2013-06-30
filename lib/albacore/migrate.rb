# -*- encoding: utf-8 -*-

require 'albacore/cmd_config'
require 'albacore/cross_platform_cmd'
require 'albacore/logging'
require 'highline/import'

module Albacore::Migrate
  class Cmd
    include ::Albacore::CrossPlatformCmd

    attr_reader :opts

    def initialize *args
      opts = Map.options(args)

      # defaults
      opts = opts.apply :extras        => [], 
                        :silent        => teamcity?,
                        :conn          => ENV['CONN'],
                        :direction     => 'migrate:up',
                        :dll           => 'src/migrations/Migrations/bin/Debug/Migrations.dll',
                        :db            => 'SqlServer2008',
                        :exe           => 'src/packages/FluentMigrator.1.0.6.0/tools/Migrate.exe',
                        :task_override => nil,
                        :interactive   => true

      e = opts.getopt(:extras)
      opts.set(:extras, e.is_a?(Array) ? e : [e]) 

      @opts = opts
      @executable = opts.get(:exe)

      conn = opts.get :conn

      if opts.get :interactive
        conn = ask "Give connection string: " do |q|
          q.validate = /\A.+\Z/
        end unless conn or opts.get(:silent)

        conn = munge_windows conn unless opts.get(:silent)

        unless opts.get :silent
          raise 'didn\'t confirm: exiting migrations' unless confirm opts.get(:direction)
        end
      end

      raise ArgumentError, 'cannot execute with empty connection string' if conn.nil? or conn.empty?

      @parameters = %W[-a #{opts.get(:dll)} -db #{opts.get(:db)} -conn #{conn}]

      if opts.get(:task_override).nil?
        @parameters.push '--task'
        @parameters.push opts.get(:direction)
      else
        @parameters.push opts.get(:task_override)
      end

      opts.get(:extras).each{|e| @parameters.push e}

      mono_command
    end

    def execute
      sh make_command
    end

    private

    def teamcity?
      ENV['TEAMCITY_VERSION'] ? true : false
    end

    def confirm direction
      agree "Please confirm #{direction}: ", false
    end

    def munge_windows conn
      if ::Rake::Win32.windows? and agree(%{
  ## Warning ##

  It seems like you are running Windows. Windows shell encodings are funny in that
  there's no standard encoding across all languages, and you can't change the
  shell encoding from a running program (such as this one), because if you do,
  and you aren't running an American or British Windows version, then the cmd.exe
  program will crash and burn.

  PLEASE ANSWER:

    Are you running from either of

      * PowerShell OR
      * Git Shell

    AND you have a Swedish operating system?}, true)
        # re-encoding connection string:
        return conn.dup.force_encoding('IBM437').encode('UTF-8')
      end
      return conn
    end

  end

  class BatchMigrateTask
    include ::Albacore::Logging

    attr_reader :args

    def initialize *args
      @args = Map.options args 
      @args.apply :direction => 'migrate:up',
                  :silent    => true
      raise 'Passed nil file' if @args.get(:file).nil?
      raise "Could not find file '#{@args.get(:file)}'" unless File.exists? @args.get(:file)
    end

    def execute
      File.open(args[:file], "r") do |file_handle|
        file_handle.each_line do |server|
          unless server.nil? or server.empty?
            info ''
            info " ********** Starting '#{server}' ************ " 
            info ''
            ::Albacore::Migrate::Cmd.new(@args.set(:conn => server)).execute
            info ''
            info " ********** Finished '#{server}' ************ " 
            info ''
          end
        end
      end
    end
  end

  class MigrateCmdFactory
    def self.create *args
      return MigrateCmd.new(*args) unless ENV['FILE']
      trace "Found FILE environment var: #{ENV['FILE']}"
      args = args.push(:file => ENV['FILE'])
      return BatchMigrateTask.new(*args)
    end
  end
end
