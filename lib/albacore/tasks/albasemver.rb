# -*- encoding: utf-8 -*-

require 'semver'
require 'albacore/logging'

module Albacore
  module AlbaSemVer
    class Error < StandardError
      attr_reader :original
      def initialize msg, original
        raise ArgumentError, "original is nil" unless original
        super msg
        @original = original
      end
      def message
        %Q{#{super.to_s}
#{@original.to_s}}
      end
    end
    class Cmd
      def initialize
      end
      def execute
        puts "TODO: execute versioning"
      end
    end
    class Config
      include Logging

      attr_accessor :tag

      def initialize
        begin
          @semver = SemVer.find
        rescue SemVerMissingError => e
          raise Error.new("could not find .semver file - please run 'semver init'", e)
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
