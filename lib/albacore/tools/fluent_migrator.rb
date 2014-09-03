# -*- encoding: utf-8 -*-

require 'albacore/cmd_config'
require 'albacore/cross_platform_cmd'
require 'albacore/logging'

module Albacore::Tools
  module FluentMigrator
    class MissingFluentMigratorExe < ::StandardError
    end

    class Cmd
      include ::Albacore::CrossPlatformCmd

      attr_reader :opts

      def initialize *args
        opts = Map.options(args)

        # defaults
        opts = opts.apply :extras        => [],
                          :silent        => ENV.fetch('MIGRATE_SILENT', teamcity?),
                          :conn          => ENV['CONN'],
                          :direction     => 'migrate:up',
                          :dll           => ENV.fetch('MIGRATE_DLL','src/migrations/Migrations/bin/Debug/Migrations.dll'),
                          :db            => ENV.fetch('MIGRATE_DB', 'SqlServer2008'),
                          :exe           => ENV.fetch('MIGRATE_EXE', 'src/packages/FluentMigrator.1.0.6.0/tools/Migrate.exe'),
                          :task_override => nil,
                          :interactive   => ENV.fetch('MIGRATE_INTERACTIVE', true),
                          :work_dir      => nil

        e = opts.getopt(:extras)
        opts.set(:extras, e.is_a?(Array) ? e : [e]) 

        @opts = opts
        @executable = opts.get(:exe)

        conn = opts.get :conn

        if opts.get :interactive
          conn = ask "Give connection string: " do |q|
            q.validate = /\A.+\Z/
          end unless opts.get(:silent) or conn

          conn = munge_windows conn unless opts.get(:silent)

          unless opts.get :silent or confirm opts.get(:direction)
            raise 'didn\'t confirm: exiting migrations'
          end

        end

        raise ArgumentError, 'cannot execute with empty connection string' if nil_or_white conn
        raise ArgumentError, 'cannot execute with no dll file specified' if nil_or_white(opts.get(:dll))

        @parameters = %W[-a #{opts.get(:dll)} -db #{opts.get(:db)} -conn #{conn} --timeout=200]

        unless opts.get :task_override
          @parameters.push '--task'
          @parameters.push opts.get(:direction)
        else
          @parameters.push opts.get(:task_override)
        end

        opts.get(:extras).each{ |e| @parameters.push e}

        trace { "configured Albacore::FluentMigrator::Cmd with exe: '#{@executable}', params: #{@parameters.join(' ')}" }
        prepare_verify @executable, opts

        mono_command
      end

      def execute
        verify_exists
        system @executable, @parameters, :work_dir => opts.get(:work_dir)
      end

      private
      def prepare_verify exe, opts
        Dir.chdir(opts.get(:work_dir) || '.') do
          @failed_verify = "Missing FluentMigrator at #{@failed_ver}" unless File.exists? exe
        end
      end

      def verify_exists
        if @failed_verify
          raise MissingFluentMigratorExe, @failed_verify
        end
      end

      def agree txt, default
        reply = default ? "[Y/n]" : "[y/N]"
        def_reply = default ? 'y' : 'n'
        STDOUT.write txt
        STDOUT.write " #{reply}: "
        res = STDIN.gets.chomp.downcase
        if res == ''
          puts "Chose #{def_reply}"
          return default
        else
          puts "Chose #{res}"
          return res == 'y'
        end
      end

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

      def nil_or_white str
        str.nil? or str.empty? 
      end

    end

    class BatchMigrateTask
      include ::Albacore::Logging

      attr_reader :args

      def initialize *args
        @args = Map.options args 
        @args.apply :direction => 'migrate:up',
                    :silent    => true
        raise ArgumentError, 'Passed nil file' if @args.get(:file).nil?
        raise ArgumentError, "Could not find file '#{@args.get(:file)}'" unless File.exists? @args.get(:file)
      end

      def execute
        File.open(args[:file], "r") do |file_handle|
          file_handle.each_line do |server|
            server = server.chomp
            unless server.nil? or server.empty?
              info ''
              info " ********** Starting '#{server}' ************ " 
              info ''
              ::Albacore::Tools::FluentMigrator::Cmd.new(@args.set(:conn => server)).execute
              info ''
              info " ********** Finished '#{server}' ************ " 
              info ''
            end
          end
        end
      end
    end

    class MigrateCmdFactory
      def initialize
        raise "don't create this class"
      end
      def self.create *args
        ::Albacore.application.logger.debug "in create"
        
        opts = Map.options args
        opts.apply :file => ENV['FILE']
        return ::Albacore::Tools::FluentMigrator::Cmd.new(*args) unless opts.get( :file )

        ::Albacore.application.logger.debug "Found FILE environment var: #{opts.get :file}"
        args = args.push(:file => opts.get(:file))
        return ::Albacore::Tools::FluentMigrator::BatchMigrateTask.new(*args)
      end
    end
  end
end
