module Albacore
  module NugetModel
    # the nuget xml metadata element writer
    class Metadata
      include Logging

      attr_accessor :id,
        :version,
        :authors,
        :description,
        :language,
        :project_url,
        :license_url,
        :release_notes,
        :owners,
        :require_license_acceptance,
        :copyright,
        :tags

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
    end
  end
end
