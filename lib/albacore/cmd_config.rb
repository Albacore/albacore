# -*- encoding: utf-8 -*-

require 'set'
require 'albacore/config_dsl'

module Albacore

  # Use on **configuration** objects that are command-oriented.
  #
  # a mixin that adds a couple of field writers and readers.
  # specifically, allows the configuration to have a work_dir and exe field
  # and defined a method that joins paths relative to the work_dir
  module CmdConfig
    include Logging
    self.extend ConfigDSL

    # TODO: move towards opts for all task types rather than
    # reading these public properties.

    # the working directory for this command
    attr_path_accessor :work_dir

    # TODO: move towards opts for all task types rather than
    # reading these public properties.

    # field field denoting the path of the executable that should be on the path
    # specified in the work_dir parameter.
    attr_path_accessor :exe

    # TODO: move towards opts for all task types rather than
    # reading these public properties.

    # returns a Set with parameters
    def parameters
      @parameters ||= Set.new
    end

    # add a parameter to the list of parameters to pass to the executable
    def add_parameter param
      parameters.add param
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
          trace "in work dir '#{@work_dir}'"
          yield
        end
      else
        trace "not in work dir, because it is nil."
        yield
      end
    end
  end
end
