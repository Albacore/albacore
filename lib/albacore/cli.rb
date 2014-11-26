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
Albacore v#{Albacore::VERSION}

init[ialze]                        # initialize a new Rakefile with defaults
help                               # display this help
version                            # display only the version of albacore

PLEASE READ https://github.com/Albacore/albacore/wiki/Albacore-binary
      HELP
    end

    command :version do
      puts "v#{Albacore::VERSION}"
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
# require 'albacore/tasks/releases'
require 'albacore/tasks/versionizer'
require 'albacore/ext/teamcity'

Configuration = 'Release'

Albacore::Tasks::Versionizer.new :versioning

desc 'create assembly infos'
asmver_files :assembly_info do |a|
  a.files = FileList['**/*proj'] # optional, will find all projects recursively by default

  a.attributes assembly_description: 'TODO',
               assembly_configuration: Configuration,
               assembly_company: 'Foretag AB',
               assembly_copyright: "(c) #{Time.now.year} by John Doe",
               assembly_version: ENV['LONG_VERSION'],
               assembly_file_version: ENV['LONG_VERSION'],
               assembly_informational_version: ENV['BUILD_VERSION']
end

desc 'Perform fast build (warn: doesn\\'t d/l deps)'
build :quick_compile do |b|
  b.logging = 'detailed'
  b.sln     = 'src/MyProj.sln'
end

task :paket_bootstrap do
  system 'tools/paket.bootstrapper.exe', clr_command: true unless \
    File.exists? 'tools/paket.exe'
end

desc 'restore all nugets as per the packages.config files'
task :restore => :paket_bootstrap do
  system 'tools/paket.exe', 'restore', clr_command: true
end

desc 'Perform full build'
build :compile => [:versioning, :restore, :assembly_info] do |b|
  b.sln = 'src/MyProj.sln'
  # alt: b.file = 'src/MyProj.sln'
end

directory 'build/pkg'

desc 'package nugets - finds all projects and package them'
nugets_pack :create_nugets => ['build/pkg', :versioning, :compile] do |p|
  p.files   = FileList['src/**/*.{csproj,fsproj,nuspec}'].
    exclude(/Tests/)
  p.out     = 'build/pkg'
  p.exe     = 'tools/NuGet.exe'
  p.with_metadata do |m|
    # m.id          = 'MyProj'
    m.title       = 'TODO'
    m.description = 'TODO'
    m.authors     = 'John Doe, Foretag AB'
    m.project_url = 'http://example.com'
    m.tags        = ''
    m.version     = ENV['NUGET_VERSION']
  end
end

namespace :tests do
  #task :unit do
  #  system "src/MyProj.Tests/bin/\#{Configuration}"/MyProj.Tests.exe"
  #end
end

# task :tests => :'tests:unit'

task :default => :create_nugets #, :tests ]

#task :ensure_nuget_key do
#  raise 'missing env NUGET_KEY value' unless ENV['NUGET_KEY']
#end

#Albacore::Tasks::Release.new :release,
#                             pkg_dir: 'build/pkg',
#                             depend_on: [:create_nugets, :ensure_nuget_key],
#                             nuget_exe: 'packages/NuGet.CommandLine/tools/NuGet.exe',
#                             api_key: ENV['NUGET_KEY']
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