# -*- encoding: utf-8 -*-

require 'set'

module Albacore

  # Use on **configuration** objects that are command-oriented.
  #
  # a mixin that adds a couple of field writers and readers.
  # specifically, allows the configuration to have a work_dir and exe field
  # and defined a method that joins paths relative to the work_dir
  module CmdConfig
    
    # the working directory for this command
    attr_accessor :work_dir
    
    # field field denoting the path of the executable that should be on the path
    # specified in the work_dir parameter.
    attr_accessor :exe
    
    # returns a Set with parameters
    def parameters
      @parameters ||= Set.new
      @parameters
    end
    
    # helper method that joins the path segments with
    # respect to the work_dir.
    private
    def join *segments
      segments ||= []
      segments.unshift work_dir
      File.join segments
    end
    
    # helper method that changes directory to the work directory
    # and then yields to the block
    def in_work_dir
      unless @work_dir.nil?
        Dir.chdir @work_dir do
          puts "in work dir '#{@work_dir}'"
          yield
        end
      else
        puts "not in work dir, because it is nil."
        yield
      end     
    end
    
    # so far not used:
    def self.param sym, required, &on_set
      raise ArgumentError, "sym needs to be a symbol" unless sym.is_a? Symbol
      @required = Set.new unless @required
      @required.add sym if required
      prop = sym.to_s
      define_method prop do
        instance_eval "@#{prop}="
      end
    end
  end
end