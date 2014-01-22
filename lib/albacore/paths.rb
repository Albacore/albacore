# -*- encoding: utf-8 -*-

require 'rake'
require 'pathname'

# module methods for handling paths
module Albacore::Paths
  class << self

    # returns the operating system separator character as a string
    def separator
      ::Albacore.windows? ? '\\' : '/'
    end

    # normalize the slashes of the path to what the operating system prefers
    def normalise_slashes path
      raise ArgumentError, "path is nil" if path.nil?
      ::Rake::Win32.windows? ? path.gsub('/', '\\') : path.gsub('\\', '/')
    end

    # make a single string-command from a given executable string, by quoting each parameter
    # individually. You can also use Albacore::CrossPlatformCmd#system given an array
    # of 'stringly' things.
    def make_command executable, parameters
      raise ArgumentError, "executable is nil" if executable.nil?
      params = parameters.collect{|p| '"' + p + '"'}.join ' '
      exe = normalise_slashes executable
      %Q{"#{exe}" #{params}}
    end


    # normalise slashes in an executable/parameters combo
    def normalise executable, parameters
      raise ArgumentError, "executable is nil" if executable.nil?
      parameters = parameters.collect{ |p| (p === String) ? p : p.to_s }
      exe = normalise_slashes executable
      ["#{exe}", parameters]
    end

    # join an Enumerable of paths by normalising slashes on each of the segments, then
    # joining them
    def join *paths
      raise ArgumentError, 'no paths given' if paths.nil?
      paths[1..-1].inject(Pathname.new(normalise_slashes(paths[0]))) { |s, t| s + normalise_slashes(t) }
    end

    # join an Enumerable of paths by normalising slashes on each of the segments, then
    # joining them, returning a string
    def join_str *paths
      normalise_slashes(join(*paths).to_s)
    end
  end
end

# Paths should be accessible if you require this file
self.include Albacore

