# -*- encoding: utf-8 -*-
require 'albacore/logging'
require 'albacore/package'

module Albacore
  # a package repository is a location where the nugets or wraps are stored
  class PackageRepo
    include Logging

    # initialize that package repository with a path to all the packages
    def initialize path
      @path = path
    end

    # find the latest package based on the package id
    def find_latest pkg_id
      trace "finding latest from #{@path}, id: #{pkg_id}"
      sorted = Dir.glob(File.join(@path, "#{pkg_id}*/**/*.dll")) # find the latest
      path = sorted.first
      Package.new pkg_id, path
    end
  end
end

