# -*- encoding: utf-8 -*-

module Albacore
  # a package encapsulates the properties of a set package with a 
  # distinct path, version and id
  class Package

    # id of the package as known by nuget
    attr_reader :id

    # path of the package in question
    attr_reader :path

    # create a new package with the given id and path
    def initialize id, path
      @id = id
      @path = path
    end

    def to_s
      "Package[#{path}]"
    end
  end
end
