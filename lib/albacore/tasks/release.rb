require 'rake'
require 'albacore/dsl'
require 'albacore/tasks/versionizer'
require 'map'

module Albacore
  module Tasks
    # The published message on a finished release
    #
    class ReleaseData
      # The semver that was released
      #
      attr_reader :semver

      # The enumerable thing of artifacts that were created from the release
      #
      attr_reader :artifacts

      # Create a new ReleaseData object with a semver (XSemVer::SemVer instance)
      # and a list of artifacts
      #
      def initialize semver, artifacts
        raise ArgumentError, 'missing "semver" argument' unless semver
        raise ArgumentError, 'missing "artifacts" argument' unless artifacts
        raise ArgumentError, '"artifacts" should respond to #each' unless artifacts.respond_to? :each
        @semver = semver
        @artifacts = artifacts
      end
    end

    # Inspiration from: https://github.com/bundler/bundler/blob/master/lib/bundler/gem_helper.rb
    #
    class Release
      include ::Rake::DSL
      include ::Albacore::DSL

      def initialize name = :release, opts = {}
        @name = name
        @opts = Map.new(opts).apply \
          pkg_dir:      'build/pkg',
          nuget_exe:    'tools/NuGet.exe',
          nuget_source: 'https://www.nuget.org/api/v2/package',
          clr_command:  true,
          depend_on:    :versioning,
          semver:       nil
        semver = @opts.get :semver

        unless semver
          ::Albacore.subscribe :build_version do |data|
            @semver = data.semver
          end
        else
          @semver = semver
        end

        install
      end

      # Installs the rake tasks under the 'release' namespace with a named task
      # (given as the first parameter to the c'tor) that calls all subtasks.
      #
      def install
        namespace :"#{@name}" do
          task :info => @opts.get(:depend_on) do
            debug do
              "Releasing to #{@opts.get :nuget_source} with task #{@name}"
            end
          end

          task :guard_clean => @opts.get(:depend_on) do
            guard_clean
          end

          task :guard_pkg => @opts.get(:depend_on) do
            guard_pkg
          end

          task :scm_write => @opts.get(:depend_on) do
            tag_version { git_push } unless already_tagged?
          end

          task :nuget_push => @opts.get(:depend_on) do
            packages.each do |package|
              nuget_push package
            end
          end
        end

        desc 'release current package(s)'
        task @name => %W|info guard_clean guard_pkg scm_write nuget_push|.map { |n| :"#{@name}:#{n}" }
      end

      protected
      def run *cmd
        block = lambda { |ok, status, output| [output, status] }
        sh(*cmd, &block)
      end

      def nuget_push package
        exe     = @opts.get :nuget_exe
        api_key = @opts.get :api_key
        params = %W|push #{package}|
        params << api_key if api_key
        params << %W|-Source #{@opts.get :nuget_source}|
        system exe, params, clr_command: @opts.get(:clr_command)
      end

      def git_push
        perform_git_push
        perform_git_push ' --tags'
        info "Pushed git commits and tags."
      end

      def perform_git_push(options = '')
        cmd = "git push #{options}"
        out, code = run cmd
        raise "Couldn't git push. `#{cmd}' failed with the following output:\n\n#{out}\n" unless code == 0
      end

      def already_tagged?
        tags = run('git tag', silent: true)[0].split(/\n/)
        if tags.include? version_tag
          warn "Tag #{version_tag} has already been created."
          true
        end
      end

      def guard_clean
        committed? or raise("There are files that need to be committed first.")
      end

      def guard_pkg
        exe = @opts.get(:nuget_exe)
        (! packages.empty?) or \
          raise("You must have built your packages for version #{nuget_version}, use 'depend_on: :nuget_pkg'")
        (File.exists?(exe)) or raise("You don't have a NuGet.exe file to push with, expected path: #{exe}")
      end

      def committed?
        run('git status --porcelain', silent: true)[0] == ""
      end

      def tag_version
        system 'git', %W|tag -a -m Version\ #{@semver.format '%M.%m.%p'} #{version_tag}|, silent: true
        info "Tagged #{version_tag}."
        yield if block_given?
      rescue
        error "Untagging #{version_tag} due to error."
        system 'git', %W|tag -d #{version_tag}|, silent: true
        raise
      end

      def version_tag
        @semver.to_s
      end

      def nuget_version
        Albacore::Tasks::Versionizer.format_nuget @semver
      end

      def packages
        # only read packages once
        path = "#{@opts.get :pkg_dir}/*.#{nuget_version}.nupkg"
        debug { "[release] looking for packages in #{path}, version #{@semver}" }
        @packages ||= Dir.glob path
        @packages
      end

      def gem_push?
        ! %w{n no nil false off 0}.include?(ENV['gem_push'].to_s.downcase)
      end
    end
  end
end
