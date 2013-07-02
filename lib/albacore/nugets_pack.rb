require 'rake'
require 'nokogiri'
require 'albacore'
require 'albacore/paths'
require 'albacore/cmd_config'
require 'albacore/cross_platform_cmd'
require 'albacore/project'
require 'albacore/logging'

module Albacore
  module NugetsPack
    class Metadata
      include Logging

      attr_accessor :id,
        :version,
        :authors,
        :description,
        :language,
        :project_url,
        :license_url,
        :release_notes

      attr_reader :dependencies, :framework_assemblies

      def initialize
        @dependencies = []
        @framework_assemblies = []
      end

      def add_depenency id, version
        @dependencies << OpenStruct.new(:id => id, :version => version)
      end

      def add_framework_dependency id, version
        @framework_assemblies << OpenStruct.new(:id => id, :version => version)
      end

      def to_xml_builder
        Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |x|
          x.metadata {
            x.id           @id
            x.version      @version
            x.authors      @authors
            x.description  @description
            x.language     @language
            x.projectUrl   @project_url
            x.licenseUrl   @license_url
            x.releaseNotes @release_notes
            x.dependencies {
              @dependencies.each { |d|
                x.dependency(:id => d.id, :version => d.version)
              }
            }
          }
        end
      end
      def to_xml
        to_xml_builder.to_xml
      end
    end

    class Package
      attr_accessor :metadata, :files
      def initialize
        @metadata = Metadata.new
        @files = []
      end
      def add_file src, target, exclude
        @files << OpenStruct.new(:src => src, :target => target, :exclude => exclude)
      end
      def to_xml_builder
        md = Nokogiri::XML(@metadata.to_xml)
        Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |x|
          x.package(:xmlns => 'http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd') {
            x << md.at_css("metadata").to_xml
            x.files {
              @files.each { |f|
                x.file(:src => f.src, :target => f.target, :exclude => f.exclude)
              }
            }
          }
        end
      end
      def to_xml
        to_xml_builder.to_xml
      end
    end

    class Cmd
      include CrossPlatformCmd
      def initialize work_dir, executable, *args
        opts = Map.options(args)
        raise ArgumentError, 'out is nil' if opts.getopt(:out).nil?
        @work_dir   = work_dir
        @executable = executable
        
        @parameters = [%W{pack -OutputDirectory #{opts.getopt(:out)}}].flatten
        mono_command
      end
      def execute nuspec_file
        @parameters << nuspec_file
        sh make_command, :work_dir => @work_dir
      end
    end

    # This tasktype allows you to quickly package project files to nuget
    # packages.
    #
    # Point files to the project files, that should be in MsBuild XML.
    #
    # Examples
    #
    #  nugets_pack :pack => ['build/pkg', :versioning] do |p|
    #    p.files   = FileList['src/**/*.csproj']
    #    p.out     = 'build/pkg'
    #    p.exe     = 'buildsupport/NuGet.exe'
    #    p.version = ENV['NUGET_VERSION']
    #  end
    class Config
      include CmdConfig

      # id is taken from the AssemblyName element in the csproj file.

      # the output directory to place the newfangled nugets in
      attr_accessor :out

      # the version to build the nugets with
      attr_accessor :version

      # the files that are enumerable and are created nugets of
      attr_accessor :files

      # the value to put for authors in the nuget package.
      attr_accessor :authors

      # the description to put in the nugets
      attr_accessor :description

      # a URL for the home page of the package.
      attr_accessor :project_url

      # a link to the license that the package is under.
      attr_accessor :license_url

      # the release notes for this package
      attr_accessor :release_notes

      def initialize
        @package = Package.new
        @authors = "TODO"
        @description = "TODO"
        @project_url = "https://example.com"
        @license_url = "https://example.com"
      end

      def opts
        Map.new({
          :out => @out
        })
      end
    end

    class ProjectTask
      include Logging

      # the package under construction
      attr_accessor :package

      def initialize command_line, config, file
        @config = config
        @file = file
        @command_line = command_line
        @package = Package.new
        @project = Albacore::Project.new @file
      end
      def prepare_dependencies
        @project.
          declared_packages.
          collect { |d| 
            OpenStruct.new(:id => d.id, :version => d.version)
          }
      end
      def prepare_nuspec filename, dependencies
        fpkg = File.join @config.out, filename
        lib = File.join fpkg, 'lib', 'net4'
        FileUtils.mkdir_p lib

        p = @package
        p.metadata.id            = @project.asmname
        p.metadata.version       = @config.version
        p.metadata.authors       = @config.authors
        p.metadata.description   = @config.description
        p.metadata.license_url   = @config.license_url
        p.metadata.project_url   = @config.project_url
        p.metadata.release_notes = @config.release_notes

        p.add_file 'lib\\**', 'lib', ''

        dependencies.each { |d|
          p.metadata.add_depenency d.id, d.version
        }

        nuspec = File.join fpkg, (filename + ".nuspec")

        File.open(nuspec, 'w') do |io|
          io.puts p.to_xml
        end
        [nuspec, lib]
      end
      def prepare_glob filename
        output = @project.proj_xml_node.at_css("PropertyGroup OutputPath").text
        output = "../#{output.gsub('\\', '/')}/#{filename}.{dll,xml}"
        File.expand_path output, @file
      end
      def execute
        filename = File.basename(@file, File.extname(@file))
        dependencies = prepare_dependencies
        debug "found #{dependencies.inspect} for dependencies"
        nuspec, lib = prepare_nuspec filename, dependencies
        project_glob = prepare_glob filename
        debug "glob: #{project_glob}"
        Dir.glob project_glob do |globbed|
          debug "cp #{globbed} #{lib}"
          FileUtils.cp globbed, lib
        end

        @command_line.execute nuspec

        path = File.join(@config.out, "#{filename}.#{@config.version}.nupkg")
        Albacore.publish :artifact, OpenStruct.new(
          :nuspec   => nuspec,
          :nupkg    => path,
          :location => path
        ) 
      end

      def self.accept? file
        File.extname(file).downcase != '.nuspec'
      end
    end
    
    class NuspecTask
      include Logging

      def initialize command_line, config, nuspec
        @config = config
        @nuspec = nuspec
        @command_line = command_line
      end

      def read_version_from_nuspec
        begin
          nuspec_file = File.open(@nuspec)
          xml = Nokogiri::XML(nuspec_file)
          nuspec_file.close
          nodes = xml.xpath('.//metadata/version')
          raise "No <version/> found" if nodes.empty?
          nodes.first.text()
        rescue => err
          puts "Error reading package version from file: #{err}"
          raise
        end
      end
      
      def execute
        version = read_version_from_nuspec
        filename = File.basename(@nuspec, File.extname(@nuspec))
        @command_line.execute @nuspec
        path = File.join(@config.out, "#{filename}.#{version}.nupkg")
        Albacore.publish :artifact, OpenStruct.new(
          :nuspec   => @nuspec,
          :nupkg    => path,
          :location => path
        )
      end

      def self.accept? file
        File.extname(file).downcase == '.nuspec'
      end
    end
  end
end
