require 'yaml'
require 'albacore/logging'

module Albacore
  # a spec object
  class AppSpec
    include ::Albacore::Logging

    # Create a new app spec from yaml data; will use heuristics to let the
    # developer avoid as much typing and definition mongering as possible; for
    # details see the unit tests and the documentation for this class.
    #
    # @descriptor_path [String] The location of the descriptor file (the .appspec)
    # @data [String] A yaml-containing string
    # @semver [::XSemVer] An optional semver instance that can be queried for what
    #   version the package has.
    def initialize descriptor_path, data, semver = nil
      raise ArgumentError, 'data is nil' unless data
      @path = descriptor_path
      @conf = YAML.load(data) || Hash.new

      project_path = resolve_project descriptor_path, @conf
      raise ArgumentError, "couldn't find project, descriptor_path: #{descriptor_path.inspect}" unless valid_path project_path

      @proj = Project.new project_path
      @semver = semver
    end

    # Resolves the project file given an optional descriptor path or a
    # configuration hash or both. One of the other of the parameters need to
    # exist, or an error will be thrown.
    #
    # @param descriptor_path May be nil
    # @param conf [#[]] A hash or something indexable
    def resolve_project descriptor_path, conf
      trace { "trying to resolve project, descriptor_path: #{descriptor_path.inspect}, conf: #{conf.inspect} [AppSpec#resolve_path]" }

      project_path = conf['project_path']
      return File.join File.dirname(descriptor_path), project_path if project_path and valid_path descriptor_path

      trace { 'didn\'t have both a project_path and a descriptor_path that was valid [AppSpec#resolve_project]' }
      return project_path if project_path
      find_first_project descriptor_path
    end

    # Given a descriptor path, tries to find the first matching project file. If
    # you have multiple project files, the order of which {Dir#glob} returns
    # values will determine which is chosen
    def find_first_project descriptor_path
      trace { "didn't have a valid project_path, trying to find first project at #{descriptor_path.inspect}" }
      dir = File.dirname descriptor_path
      abs_dir = File.expand_path dir
      Dir.glob(File.join(abs_dir, '*proj')).first
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

    # gets the binary folder, first from .appspec then from proj given a configuration
    # mode (default: Release)
    def bin_folder configuration = 'Release'
      conf['bin'] || proj.output_path(configuration)
    end

    # gets the folder that is used to keep configuration that defaults
    # to the current (.) directory
    def conf_folder
      conf['conf_folder'] || '.'
    end

    # gets an enumerable list of paths that are the 'main' contents of the package
    #
    def contents
      conf['contents'] || []
    end

    # TODO: support a few of these: https://github.com/bernd/fpm-cookery/wiki/Recipe-Specification

    # load the App Spec from a descriptor path
    def self.load descriptor_path
      raise ArgumentError, 'missing parameter descriptor_path' unless descriptor_path
      raise ArgumentError, 'descriptor_path does not exist' unless File.exists? descriptor_path
      AppSpec.new(descriptor_path, File.read(descriptor_path))
    end

    # Customizing the to_s implementation to make the spec more amenable for printing
    def to_s
      "AppSpec[#{title}], #{@conf.keys.length} keys]"
    end

    private
    # determines whether the passed path is valid and existing
    def valid_path path
      path and File.exists? path
    end

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
