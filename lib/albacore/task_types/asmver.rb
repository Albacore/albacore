# -*- encoding: utf-8 -*-

require 'set'
require 'albacore/logging'
require 'albacore/cross_platform_cmd'
require 'albacore/errors/unfilled_property_error'
require 'albacore/asmver/cs'
require 'albacore/asmver/vb'
require 'albacore/asmver/cpp'
require 'albacore/asmver/fs'

module Albacore
  module AsmVer
    class Cmd
      include Logging
      def initialize project
        trace "intializing cmd with #{project.inspect}"
        @parameters = Set.new
      end
      def execute
      end
    end
    class Config
      # :prefix sets the filename prefix (excluding extension) to generate
      attr_accessor :version, :files, :prefix
      
      def initialize
        @files_config = proc { |project_root|  }
      end
      
      # lets the Rakefile configure the path to the Assembly Info
      def out_file &config_block
        @files_config = config_block
      end
      
      Project = Struct.new(:file_path, :dir_path, :lang_ext, :version, :asminfo_path)
    
      # return all project meta-datas
      def projects
        raise ArgumentError, "config.files must respond to #each/1" unless @files.respond_to? :each
        raise UnfilledPropertyError, "version", "must be set: ver.version = '2.4.5'" unless @version
        @files.collect { |f|
          proj = Project.new(f, File.dirname(f), guess_lang_ext(f), @version)
          proj.asminfo_path = @files_config.call proj.dir_path, proj
          proj
        }
      end
      
      private
      def guess_lang_ext path
        case File.extname path
          when ".fsproj" then ".fs"
          when ".csproj" then ".cs"
          when ".vbproj" then ".vb"
        end
      end
    end
    class Task
      def initialize cmd
        @cmd = cmd
      end
      def execute
        @cmd.execute
      end
    end
  end
end
