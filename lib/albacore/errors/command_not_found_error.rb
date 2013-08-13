# -*- encoding: utf-8 -*-

module Albacore
  class CommandNotFoundError < StandardError

    attr_reader :executable

    def initialize message, executable
      super(message)
      @executable = executable
    end
  end
end
