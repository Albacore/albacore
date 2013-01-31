# -*- encoding: utf-8 -*-

module Albacore
  def self.configure
  end

  def subscribe event, &block
  	event = event.to_sym unless event.is_a? Symbol
  	@events ||= {}
  	@events[event] ||= Set.new
  	@events[event].add block 
  end

  def publish event, obj
    @events.include? ...
  end
end