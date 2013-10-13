# -*- encoding: utf-8 -*-
require 'logger'
require 'albacore/application'

module Albacore
  module Logging
    def trace *str, &block
      ::Albacore.application.logger.debug *str, &block
    end
    def debug *str, &block
      ::Albacore.application.logger.debug *str, &block
    end
    def info *str, &block
      ::Albacore.application.logger.info *str, &block
    end
    def warn *str, &block
      ::Albacore.application.logger.warn *str, &block
    end
    def error *str, &block
      ::Albacore.application.logger.error *str, &block
    end
    def fatal *str, &block
      ::Albacore.application.logger.fatal *str, &block
    end
    def puts *str
      ::Albacore.application.puts *str
    end
    def err str
      ::Albacore.application.err str
    end
  end
end
