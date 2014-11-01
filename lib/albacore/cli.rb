require 'albacore/version'
require 'albacore/cross_platform_cmd'
require 'albacore/cli_dsl'

module Albacore
  class Cli
    include Albacore::CliDSL

    def initialize args
      # Run a semver command. Raise a CommandError if the command does not exist.
      # Expects an array of commands, such as ARGV.
      @args = args
      run_command(@args.shift || :help)
    end

    private

    def next_param_or_error(error_message)
      @args.shift || raise(CommandError, error_message)
    end

    # Gets the help text if the command line is used in the wrong way
    def help_text
      <<-HELP
albacore commands
-----------------

init[ialze]                        # initialize a new Rakefile with defaults
help                               # display this help

PLEASE READ https://github.com/Albacore/albacore/wiki/Albacore-binary
      HELP
    end

    # Create a new Rakefile file if the file does not exist.
    command :initialize, :init do
      files = [Albacore.rakefile, Albacore.gemfile, Albacore.semver_file]
      if files.any? { |file| File.exist? file }
        puts "One of #{files.inspect} already exists"
      else
        Albacore::CrossPlatformCmd.system 'semver init' unless ENV['TEST']
        File.open Albacore.gemfile, 'w+' do |io|
          io.puts <<-DATA
source 'https://rubygems.org'
gem 'albacore', '~> #{Albacore::VERSION}'
          DATA
        end
        Albacore::CrossPlatformCmd.system 'bundle'
        File.open Albacore.rakefile, 'w+' do |io|
          io.puts <<-DATA
require 'bundler/setup'

require 'albacore'
require 'albacore/tasks/versionizer'
require 'albacore/ext/teamcity'

Albacore::Tasks::Versionizer.new :versioning

desc 'Perform fast build (warn: doesn\\'t d/l deps)'
build :quick_build do |b|
  b.logging = 'detailed'
  b.sln     = 'src/MyProj.sln'
end

desc 'restore all nugets as per the packages.config files'
nugets_restore :restore do |p|
  p.out = 'src/packages'
  p.exe = 'tools/NuGet.exe'
end

desc 'Perform full build'
build :build => [:versioning, :restore] do |b|
  b.sln = 'src/MyProj.sln'
  # alt: b.file = 'src/MyProj.sln'
end

directory 'build/pkg'

desc 'package nugets - finds all projects and package them'
nugets_pack :create_nugets => ['build/pkg', :versioning, :build] do |p|
  p.files   = FileList['src/**/*.{csproj,fsproj,nuspec}'].
    exclude(/Tests/)
  p.out     = 'build/pkg'
  p.exe     = 'tools/NuGet.exe'
  p.with_metadata do |m|
    m.description = 'A cool nuget'
    m.authors = 'Henrik'
    m.version = ENV['NUGET_VERSION']
  end
  p.with_package do |p|
    p.add_file 'file/relative/to/proj', 'lib/net40'
  end
end

task :default => :create_nugets
          DATA
        end
      end
    end

    # Output instructions for using the semvar command.
    command :help do
      puts help_text
    end
  end
end