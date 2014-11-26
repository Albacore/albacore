require 'albacore/version'
require 'albacore/cross_platform_cmd'
require 'albacore/cli_dsl'
require 'open-uri'

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
      files = [Albacore.rakefile, Albacore.semver_file]
      if files.any? { |file| File.exist? file }
        puts "One of #{files.inspect} already exists"
      else
        write_semver! unless ENV['TEST']
        write_gemfile
        bundle!
        write_gitignore
        write_rakefile!
        download_paket unless ENV['TEST']
      end
    end

    # Output instructions for using the semvar command.
    command :help do
      puts help_text
    end

    private
    def write_semver!
      Albacore::CrossPlatformCmd.system 'semver init'
    end

    def write_gemfile
      unless File.exists? Albacore.gemfile
        File.open Albacore.gemfile, 'w+' do |io|
          io.puts <<-DATA
source 'https://rubygems.org'
gem 'albacore', '~> #{Albacore::VERSION}'
          DATA
        end
      end
    end

    def bundle!
      Albacore::CrossPlatformCmd.system 'bundle'
    end

    def write_gitignore
      unless File.exists? '.gitignore'
        File.open '.gitignore', 'w+' do |io|
          io.puts %{
paket.exe
bin/
obj/
.DS_Store
*.db
*.suo
*.userprefs
AssemblyVersionInfo.cs
AssemblyVersionInfo.fs
AssemblyVersionInfo.vb
}
        end
      end
    end

    def write_rakefile!
      # guesses:
      sln = Dir.glob('**/*.sln').first || 'MyProj.sln'

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
  b.sln     = '#{sln}'
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
  b.sln     = '#{sln}'
end

directory 'build/pkg'

desc 'package nugets - finds all projects and package them'
nugets_pack :create_nugets => ['build/pkg', :versioning, :compile] do |p|
  p.files   = FileList['src/**/*.{csproj,fsproj,nuspec}'].
    exclude(/Tests/)
  p.out     = 'build/pkg'
  p.exe     = 'packages/NuGet.CommandLine/tools/NuGet.exe'
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

      def download_paket
        download_tool 'https://github.com/fsprojects/Paket/releases/download/0.16.2/paket.bootstrapper.exe', 'paket.bootstrapper.exe' unless File.exists? './tools/paket.bootstrapper.exe'
      end

      def download_tool uri, file_name
        target = "./tools/#{file_name}"

        File.open(target, "wb") do |saved_file|
          open(uri, "rb") do |read_file|
            saved_file.write(read_file.read)
          end
        end
      end
    end
  end
end