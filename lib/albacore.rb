# -*- encoding: utf-8 -*-

require 'albacore/version'
require 'albacore/logging'

require 'albacore/asmver'
require 'albacore/asminfo'
require 'albacore/build'
require 'albacore/nugets_restore'
require 'albacore/restore_hint_paths'
require 'albacore/test_runner'

module Albacore
  class << self
    # Set the global albacore logging level
    def log_level= level
      @level = level.is_a?(Albacore::Logging::LogLevel) ? level : Albacore::Logging::LogLevel.new(level)
    end
  end
end