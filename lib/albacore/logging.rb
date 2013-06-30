# -*- encoding: utf-8 -*-
require 'logger'
require 'albacore/application'

module Albacore
  module Logging
    def trace str
      ::Albacore.application.logger.debug str
    end
    def debug str
      ::Albacore.application.logger.debug str
    end
    def info str
      ::Albacore.application.logger.info str
    end
    def warn str
      ::Albacore.application.logger.warn str
    end
    def error str
      ::Albacore.application.logger.error str
    end
    def fatal str
      ::Albacore.application.logger.fatal str
    end
    def puts str
      ::Albacore.application.puts str
    end
  end
end
