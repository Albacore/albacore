require 'yaml'

module Albacore
  # a spec object
  class AppSpec

    # create a new app spec from yaml data
    #
    # @descriptor_path The location of the descriptor file (the .appspec)
    # @data A yaml-containing string
    # @semver [XSemVer] An optional semver instance that can be queried for what
    #   version the package has.
    def initialize descriptor_path, data, semver = nil
      raise ArgumentError, 'data is nil' unless data
      @path = descriptor_path
      @conf = YAML.load data
      @proj = Project.new @conf['project_path']
      @semver = semver
    end

    # path of the *.appspec
    attr_reader :path

    # the loaded configuration in that appspec
    attr_reader :conf

    # the project the spec applies to
    attr_reader :proj

    # gets the fully qualified path of the directory where the appspec file is
    def dir_path
      File.expand_path(File.dirname(@path))
    end

    # title for puppet, title for app, title for process running on server
    def title
      t = conf['title'] || proj.title
      t.downcase
    end

    # the description that is used when installing and reading about the package in the
    # package manager
    def description
      conf['description'] || proj.description
    end

    # gets the uri source of the project
    def uri
      conf['uri'] || git_source
    end

    # gets the category this package is in, both for the RPM and for puppet and
    # for possibly assigning to a work-stealing cluster or to start the app in
    # the correct node-cluster if you have that implemented
    def category
      conf['category'] || 'apps'
    end

    # gets the license that the app is licensed under
    def license
      conf['license'] || proj.license
    end

    # gets the version
    def version
      semver_version || conf['version'] || proj.version
    end

    # load the App Spec from a descriptor path
    def self.load descriptor_path
      raise ArgumentError, 'missing parameter descriptor_path' unless descriptor_path
      AppSpec.new(descriptor_path, File.read(descriptor_path))
    end

    private
    # gets the source from the current git repository: finds the first remote and uses
    # that as the source of the RPM
    def git_source
      `git remote -v`.
        split(/\n/).
        map(&:chomp).
        map { |s| s.split(/\t/)[1].split(/ /)[0] }.
        first
    end

    # Gets the semver version in %M.%m.%p form or nil if a semver isn't given.
    def semver_version
      return @semver.format '%M.%m.%p' if @semver
      nil
    end
  end
end
