require 'set'
require 'albacore/logging'
require 'albacore/cross_platform_cmd'
require 'albacore/cmd_config'
require 'albacore/errors/unfilled_property_error'
require 'albacore/project'
require 'albacore/task_types/asmver/cs'
require 'albacore/task_types/asmver/vb'
require 'albacore/task_types/asmver/cpp'
require 'albacore/task_types/asmver/fs'
require 'albacore/task_types/asmver/file_generator'

module Albacore
  module Asmver
    class MultipleFilesConfig
      include ::Albacore::Logging

      # list of xxproj files to iterate over
      attr_writer :files

      def initialize
        @usings = []
      end

      def attributes attrs
        @attributes = attrs
      end

      def using ns
        debug { "adding namespace #{ns} [Asmver::MultipleFilesConfig using]" }
        @usings << ns
      end

      # block should have signature: Project -> AsmVer::Config -> AsmVer::Config
      # because you can use this block to change the configuration generated
      def handle_config &block
        @handle_config = block
      end

      def configurations
        @files ||= FileList['**/*.{fsproj,csproj,vbproj}']

        debug { "generating config for files: #{@files}" }

        @files.map { |proj|
            proj =~ /(\w\w)proj$/
            [ $1, Project.new(proj) ]
          }.map { |ext, proj|
            attrs = @attributes.clone
            attrs[:assembly_title] = proj.name
            file_path = "#{proj.proj_path_base}/AssemblyVersionInfo.#{ext}"
            cfg = Albacore::Asmver::Config.new file_path, proj.asmname, attrs
            cfg = @handle_config.call(proj, cfg) if @handle_config
            cfg.usings = @usings.clone
            cfg
          }
      end
    end

    # Raised when the configuration is missing where to write the file.
    class MissingOutputError < StandardError
    end

    class Config
      include CmdConfig
      self.extend ConfigDSL

      # the file name to write the assembly info to
      attr_path_accessor :file_path

      # the namespace to output into the version file
      attr_accessor :namespace

      # (optional) output stream
      attr_accessor :out

      # the array-like thing of using namespaces
      attr_accessor :usings

      # creates a new config with some pre-existing data
      def initialize file_path = nil, namespace = nil, attributes = nil
        @file_path, @namespace, @attributes = file_path, namespace, attributes
        @usings = []
      end

      # Call with to get the opportunity to change the attributes hash
      def change_attributes &block
        yield @attributes if block
      end

      # Give the hash of attributes to write to the assembly info file
      def attributes attrs
        @attributes = attrs
      end

      def using ns
        debug { "adding namespace #{ns} [Asmver::Config using]" }
        usings << ns
      end

      # @return Map object
      def opts
        raise MissingOutputError, "#file_path or #out is not set" unless (file_path or out)
        ns   = @namespace || '' # defaults to empty namespace if not set.
        lang = lang_for file_path
        m = Map.new attributes: @attributes,
                    namespace: ns,
                    file_path: @file_path,
                    language:  lang,
                    usings: usings
        m[:out] = out if out
        m
      end

      def to_s
        "AsmVer::Config[#{file_path}]"
      end

      private

      def lang_for path
        mk = lambda { |lang| "Albacore::Asmver::#{lang}".split('::').inject(Object) { |o, c| o.const_get c }.new }
        case File.extname path
          when ".fs" then mk.call "Fs"
          when ".cs" then mk.call "Cs"
          when ".vb" then mk.call "Vb"
          when ".cpp" then mk.call "Cpp"
        end
      end
    end

    class Task
      include Logging
      def initialize opts
        @opts = opts
      end
      def execute
        lang  = @opts.get :language
        ns    = @opts.get :namespace
        attrs = @opts.get :attributes
        out   = @opts.get :out do
          trace { "asmver being written at '#{@opts.get :file_path}' [asmver-task #execute]" }
          File.open(@opts.get(:file_path), 'w')
        end
        ::Albacore::Asmver::FileGenerator.new(lang, ns, @opts).generate out, attrs
        trace { "asmver was written at '#{@opts.get :file_path}' [asmver-task #execute]" }
      ensure
        out.close if out
      end
    end
  end
end
