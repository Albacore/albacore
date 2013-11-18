require 'set'
require 'albacore/logging'
require 'albacore/cross_platform_cmd'
require 'albacore/cmd_config'
require 'albacore/errors/unfilled_property_error'
require 'albacore/task_types/asmver/cs'
require 'albacore/task_types/asmver/vb'
require 'albacore/task_types/asmver/cpp'
require 'albacore/task_types/asmver/fs'
require 'albacore/task_types/asmver/file_generator'

module Albacore
  module Asmver
    class Config
      include CmdConfig
      self.extend ConfigDSL

      # the file name to write the assembly info to
      attr_path_accessor :file_path

      # the namespace to output into the version file
      attr_writer :namespace


      # (optional) output stream
      attr_writer :out

      def initialize
      end

      # the hash of attributes to write to the assembly info file
      def attributes attrs
        @attributes = attrs
      end
      
      def opts
        raise Error, "#file_path is not set" unless (file_path or out)
        ns   = @namespace || '' # defaults to empty namespace if not set.
        lang = lang_for file_path
        m = Map.new attributes: @attributes,
          namespace: ns,
          file_path: @file_path,
          language:  lang
        m[:out] = @out if @out
        m
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
