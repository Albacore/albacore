module Albacore
  class CommandFailedError < StandardError

    attr_reader :executable

    attr_reader :output

    def initialize message, executable, output = nil
      super(message)
      @executable = executable
      @output = output
    end

    def message
      s = StringIO.new
      s.puts super
      s.puts output if output
      s.string
    end
  end
end
