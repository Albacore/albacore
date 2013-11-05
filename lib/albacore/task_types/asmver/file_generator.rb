require 'albacore/task_types/asmver/engine'
require 'map'

module Albacore::Asmver
  class FileGenerator
    DEFAULT_USINGS = %w|
System.Reflection
System.Runtime.CompilerServices
System.Runtime.InteropServices|

    def initialize engine, ns, opts
      raise ArgumentError, 'engine is nil' unless engine
      raise ArgumentError, 'ns is nil' unless ns
      @engine = engine 
      @ns     = ns
      @opts   = Map.new(opts)
    end
    
    def generate attrs = {}
      # https://github.com/ahoward/map/blob/master/test/map_test.rb#L374
      attrs = Map.new attrs
      s = @opts.get(:out) { StringIO.new }

      # write the attributes in the namespace
      @engine.build_namespace @ns, s do
        # after namespace My.Ns.Here
        s << "\n"

        # open all namespaces to use .Net attributes
        @opts.get(:usings) { DEFAULT_USINGS }.each do |ns|
          s << @engine.build_using_statement(ns)
          s << "\n"
        end

        # write all attributes
        attrs.each do |name, data|
          s << @engine.build_attribute(name, data)
          s << "\n"
        end
      end

      s.string
    end
  end
end
