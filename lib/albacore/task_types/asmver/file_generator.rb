require 'albacore/task_types/asmver/engine'
require 'albacore/logging'
require 'map'

module Albacore::Asmver
  class FileGenerator
    include ::Albacore::Logging

    DEFAULT_USINGS = %w|
System.Reflection
System.Runtime.CompilerServices
System.Runtime.InteropServices|

    def initialize engine, ns, opts
      raise ArgumentError, 'engine is nil' unless engine
      raise ArgumentError, 'ns is nil' unless ns
      @engine = engine 
      @ns     = ns
      @opts   = Map.new opts
    end

    def generate out, attrs = {}
      trace { "generating file with attributes: #{attrs} [file_generator #generate]" }

      # https://github.com/ahoward/map/blob/master/test/map_test.rb#L374
      attrs = Map.new attrs

      # write the attributes in the namespace
      @engine.build_namespace @ns, out do
        # after namespace My.Ns.Here
        out << "\n"

        # open all namespaces to use .Net attributes
        @opts.get(:usings) { DEFAULT_USINGS }.each do |ns|
          out << @engine.build_using_statement(ns)
          out << "\n"
        end

        warn 'no attributes have been given to [file_generator #generate]' if attrs.empty?

        # write all attributes
        attrs.each do |name, data|
          trace { "building attribute #{name}: '#{data}' [file_generator #generate]" }
          out << @engine.build_attribute(name, data)
          out << "\n"
        end
      end

      nil
    end
  end
end
