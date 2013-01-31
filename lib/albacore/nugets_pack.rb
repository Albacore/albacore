require 'rake'
require 'nokogiri'
require 'albacore/paths'
require 'albacore/cmd_config'
require 'albacore/cross_platform_cmd'

module Albacore
  module NugetsPack
    class Metadata
      def self.attr_accessor *vars
        @attributes ||= []
        @attributes.concat vars
        super
      end
      def self.attributes
        @attributes
      end
      attr_accessor :id, 
        :version, 
        :authors, 
        :description, 
        :language, 
        :projectUrl, 
        :licenseUrl, 
        :dependencies,
        :frameworkAssemblies

      def to_xml_builder
        Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |x|
          x.metadata {
            self.class.attributes.each do |a|
              x.send(a, send(a))
            end
          }
        end
      end
    end
    class Package
      attr_accessor :metadata, :files
      def initialize
        @metadata = Metadata.new
        @files = []
      end
      def to_xml_builder
        md = Nokogiri::XML::Document.new @metadata.to_xml_builder.to_xml
        Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |x|
          x.package('xmlns' => 'http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd') {
            x.metadata md.at_css("metadata").to_s
          }
        end
      end
    end
    class Cmd
      include CrossPlatformCmd
      def initialize work_dir, executable, out, opts
        #opts = Map.options(opts)
        @executable = executable 
        @work_dir   = work_dir
        @parameters = %W{pack -OutputDirectory #{out}}
      end
      def execute
        sh make_command 
      end
    end
    class Config
      include CmdConfig
      
      # the output directory to place the newfangled nugets in
      attr_accessor :out
      
      def files= fs
        @files = fs
      end

      def files
        @files
      end

      def opts ; end
    end
    class Task
      def initialize command_line
        
        @command_line = command_line
      end
      def execute
        # create nuspec::TODO
        

        @command_line.execute
      end
    end
  end
end
