require 'rake'
require 'albacore'
require 'albacore/package'
require 'albacore/cmd_config'
require 'albacore/config_dsl'
require 'albacore/cross_platform_cmd'
require 'albacore/project'
require 'albacore/logging'
require 'albacore/nuget_model'

module Albacore
  module NugetsPack

    class Config
      include CmdConfig

      def initialize
        @symbols = true
        @transitive = true
        @pin = false
        @exe = '.paket/paket.exe'
        @files = []
        @metadata = Albacore::NugetModel::Metadata.new
      end

      attr_accessor :configuration
      attr_accessor :exe
      attr_accessor :output
      attr_accessor :files
      attr_accessor :metadata

      def not_symbols
        @symbols = false
      end

      def symbols?
        @symbols
      end

      def not_transitive
        @transitive = false
      end

      def transitive?
        @transitive
      end

      def pin
        @pin = true
      end

      def pin?
        @pin
      end

      def method_missing(m, *args, &block)
        @metadata.send(m, *args, &block)
      end

      def validate
        if configuration.nil?
          raise '"configuration" is a required property'
        end
        if version.nil?
          raise '"version" is a required property'
        end
      end

      def fallbacks!
        if @metadata.release_notes.nil?
          notes = Albacore::Tools.git_release_notes
          @metadata.release_notes = notes
        end
      end
    end

    class Cmd
      include CrossPlatformCmd

      def initialize config
        @executable = config.exe
        @config = config
      end

      def execute
        @config.validate
        @config.fallbacks!
        invocations(@config).each do |parameters|
          system @executable, parameters, clr_command: true
        end
      end

    private
      def defaults config
        parameters = []
        parameters = %w|pack|
        parameters << config.output unless config.output.nil?
        parameters << '--version' unless config.version.nil?
        parameters << config.version unless config.version.nil?
        parameters << '--build-config'
        parameters << config.configuration
        parameters << '--include-referenced-projects' if config.transitive?
        parameters << '--symbols' if config.symbols?
        parameters << '--project-url' if config.project_url
        parameters << config.project_url if config.project_url
        parameters
      end

      def invocations config
        if config.files.empty?
          [ defaults(config) ]
        else
          config.files.map do |file|
            proj = Albacore::Project.new file
            package = Albacore::NugetModel::Package.from_xxproj proj,
              configuration: config.configuration,
              metadata: config.metadata

            path = File.join(proj.proj_path_base, "paket.template")

            File.open(path, 'w') do |template|
              template.write package.to_template
            end

            parameters = defaults config
            parameters << '--template'
            parameters << path
            [ parameters ]
          end
        end
      end
    end
  end
end