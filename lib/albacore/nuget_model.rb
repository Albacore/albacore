require 'map'

module Albacore
  module NugetModel
    # the nuget xml metadata element writer
    class Metadata
      include Logging

      # gets or sets the id of this package
      attr_accessor :id
      
      # gets or sets the version of this package
      attr_accessor :version

      # gets or sets the authors of this package
      attr_accessor :authors

      # gets or sets the description of this package
      attr_accessor :description

      # gets or sets the language that this package has been built with
      attr_accessor :language

      # gets or sets the project url for this package
      attr_accessor :project_url

      # gets or sets the license url for this package
      attr_accessor :license_url

      # gets or sets the release notes for this build.
      attr_accessor :release_notes

      # gets or sets the owners of this package
      attr_accessor :owners

      # gets or sets whether this package requires a license acceptance from the user
      # hint: don't.
      attr_accessor :require_license_acceptance

      # gets or sets the copyright for this package
      attr_accessor :copyright

      # get or sets the tags for this package
      attr_accessor :tags

      # get the dependent nuget packages for this package
      attr_reader :dependencies

      # gets the framework assemblies for this package
      attr_reader :framework_assemblies

      # initialise a new package data object
      def initialize
        @dependencies = []
        @framework_assemblies = []
      end

      # add a dependency to the package; id and version
      def add_dependency id, version
        @dependencies << OpenStruct.new(:id => id, :version => version)
      end

      # add a framework dependency for the package
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
            x.owners       @owners
            x.requireLicenseAcceptance @require_license_acceptance
            x.dependencies {
              @dependencies.each { |d|
                x.dependency(:id => d.id, :version => d.version)
              }
            }
          }
        end
      end

      # transform the data structure to the corresponding xml
      def to_xml
        to_xml_builder.to_xml
      end
      def self.from_xml node
        Albacore.application.logger.debug { "constructing NugetModel::Metadata from node #{node.inspect}" }

        m = Metadata.new
        node.children.reject { |n| n.text? }.each do |n|
          if n.name == 'dependencies'
            n.children.reject { |n| n.text? }.each do |dep|
              m.add_dependency dep['id'], dep['version']
            end
          elsif n.name == 'frameworkDepdendencies'
            n.children.reject { |n| n.text? }.each do |dep|
              m.add_framework_depdendency dep['id'], dep['version']
            end 
          else
            # just set the property
            m.send(:"#{underscore n.name}=", n.inner_text)
          end
        end
        m
      end
      
      def self.underscore str
        str.gsub(/::/, '/').
          gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
          gsub(/([a-z\d])([A-Z])/,'\1_\2').
          tr("-", "_").
          downcase
      end
    end

    # the nuget package element writer
    class Package

      attr_accessor :metadata, :files

      def initialize metadata = nil, files = nil
        @metadata = metadata || Metadata.new
        @files = files || []
      end

      # add a file to the instance
      def add_file src, target, exclude
        @files << OpenStruct.new(:src => src, :target => target, :exclude => exclude)
      end

      # gets the current package as a xml builder
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

      # gets the current package as a xml node
      def to_xml
        to_xml_builder.to_xml
      end

      # read the nuget specification from a nuspec file
      def self.from_xml xml
        parser = Nokogiri::XML(xml)
        meta = Metadata.from_xml(parser.xpath('.//metadata'))
        files = parser.
          xpath('.//files').
          children.
          reject { |n| n.text? or n['src'].nil? }.
          collect { |n|
            h = { :src => n['src'], :target => n['target'], :exclude => n['exclude'] }
            OpenStruct.new h
          }
        Package.new meta, files
      end

      # read the nuget specification from a xxproj file (e.g. csproj, fsproj)
      def self.from_xxproj file, *opts
        opts = Map.options opts
        proj = Albacore::Project.new file
        package = Package.new
        package.metadata.id = proj.name
        package.metadata.version = proj.version
        package.metadata.authors = proj.authors

        if opts.get :include_compile_files, false 
          compile_files = proj.included_files.keep_if { |f| f.item_name == "compile" }
          Albacore.application.logger.debug "including compile files: #{compile_files}"
          compile_files.each do |f|
            exclude = ""
            target = File.join 'src', f.include
            package.add_file f.include, target, exclude
          end 
        end
        package
      end
    end
  end
end
