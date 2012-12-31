# -*- encoding: utf-8 -*-

module Albacore
  class UnfilledPropertyError < StandardError
    attr_accessor :property
    def initialize property, message
      super(message)
      @property = property
    end
    def message
      %Q{The property "#{property}"; #{message}}
    end
  end
end