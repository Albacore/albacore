# -*- encoding: utf-8 -*-

module Albacore
  module Logging
    def trace str
      # puts str
    end
    def debug str
      puts str
    end
    def info str
      puts str
    end
    def error str
      puts str
    end
    
    class LogLevel
      attr_reader :level
      def initialize level
        @level = level || :trace
        @levels = {
          :trace => 0,
          :debug => 1,
          :info  => 2,
          :error => 3
        }
      end
      def <=> other
        other_level = @levels[other.level]
        @levels[self.level] <=> other_level
      end
    end
  end
end