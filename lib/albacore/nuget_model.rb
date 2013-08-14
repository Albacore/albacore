module Albacore
  module NugetModel
    # the nuget xml metadata element
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

      def add_dependency id, version
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

    # the nuget package element
    class PackageWriter
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
  end
end
