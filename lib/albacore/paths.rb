# -*- encoding: utf-8 -*-

require 'rake'

module Albacore
  # module methods for handling paths
  module Paths
    class << self
      # normalize the slashes of the path to what the operating system prefers
      def normalise_slashes path
        raise ArgumentError, "path is nil" if path.nil?
        ::Rake::Win32.windows? ? path.gsub('/', '\\') : path.gsub('\\', '/')
      end

      def make_command executable, parameters
        raise ArgumentError, "executable is nil" if executable.nil?
        params = parameters.collect{|p| '"' + p + '"'}.join ' '
        exe = normalise_slashes executable
        %Q{"#{exe}" #{params}}
      end

      def normalise executable, parameters
        raise ArgumentError, "executable is nil" if executable.nil?
        parameters = parameters.collect{ |p| (p === String) ? p : p.to_s }
        exe = normalise_slashes executable
        ["#{exe}", parameters]
      end
    end
  end
end
