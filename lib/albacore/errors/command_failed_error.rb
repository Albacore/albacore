module Albacore
  class CommandFailedError < StandardError

    attr_reader :executable

    def initialize message, executable
      super(message)
      @executable = executable
    end
  end
end
