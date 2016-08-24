require 'albacore/logging'
require 'albacore/project'

module Albacore
  # a solution encapsulates the properties from a sln file.
  class Solution
    include Logging

    attr_reader :path_base, :filename, :content

    def initialize path
      raise ArgumentError, 'solution path does not exist' unless File.exists? path.to_s
      path = path.to_s unless path.is_a? String
      @content = open(path)
      @path_base, @filename = File.split path
    end

    def projects
      project_paths.map { |path| File.join(@path_base, path) }
                   .select { |path| File.file?(path) }
                   .map {|path| Albacore::Project.new(File.absolute_path(path)) }
    end

    def project_paths
      project_matches.map { |matches| matches[:location] }
                     .select { |path| File.extname(path).end_with? 'proj' }

    end

    # get the path of the solution file
    def path
      File.join @path_base, @filename
    end

    # Gets the path of the solution file
    def to_s
      path
    end

    private

    def project_matches
      project_regexp = /^\s*Project\(.+\) = "(?<name>.+?)", "(?<location>.+?)", "(?<guid>.+?)"/
      @content.map { |line| project_regexp.match(line) }.reject(&:nil?)
    end
  end
end
