require 'albacore/dsl'
require 'map'

module Albacore
  module Tasks
    # Inspiration from: https://github.com/bundler/bundler/blob/master/lib/bundler/gem_helper.rb
    #
    class Releases
      include ::Albacore::DSL if defined? ::Albacore::DSL
      
      def initialize name = :release, semver = nil, opts = {}
        @name = name
        @opts = Map.apply(opts,
          pkg_dir: 'build/pkg',
          nuget_exe: 'tools/NuGet.exe',
          nuget_source: 'https://www.nuget.org/api/v2/package',
          clr_command: true,
          depend_on: :versioning)

        raise ArgumentError, 'missing :api_key from opts' unless @opts.get :api_key

        unless semver
          ::Albacore.subscribe :build_version do |data|
            @semver = data.semver
          end
        else
          @semver = semver
        end
      end

      def install
        namespace :release do
          task :guard_clean => @opts.get(:depend_on) do
            guard_clean
          end

          task :scm_write => @opts.get(:depend_on) do
            tag_version { git_push } unless already_tagged?
          end

          task :nuget_push => @opts.get(:depend_on) do
            packages = Dir.glob "#{@opts.get :pkg_dir}/*.#{@semver.format "%M.%m.%p"}.nupkg"
            packages.each do |package|
              nuget_push package
            end
          end
        end

        desc 'release current packages'
        task @name => [:'release:guard_clean', :'release:scm_write', :'release:nuget_push']
      end

      protected
      def run *cmd
        block = lambda { |ok, status, output| [output, status] }
        sh(*cmd, &block)
      end

      def nuget_push package
        system @opts.get(:nuget_exe),
               %W|push #{package} #{@opts.get :api_key} -Source #{@opts.get :nuget_source}|,
               clr_command: @opts.get(:clr_command)
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
        clean? && committed? or raise("There are files that need to be committed first.")
      end

      def clean?
        run('git diff --exit-code', silent: true)[1] == 0
      end

      def committed?
        run('git diff-index --quiet --cached HEAD', silent: true)[1] == 0
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

      def gem_push?
        ! %w{n no nil false off 0}.include?(ENV['gem_push'].to_s.downcase)
      end
    end
  end
end
