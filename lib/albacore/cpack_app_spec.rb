require 'albacore/app_spec'
require 'albacore/errors/invalid_app_spec_error'
require 'map'

module Albacore
  class CpackAppSpec
  end

  class CpackAppSpec::Config
    # create a new configuration for multiple xxproj-s to be packed with fpm into .deb/.rpm
    def initialize
      @files         = []
      @out           = '.'
      @configuration = 'Release'
    end

    # set the output path, defaults to '.'
    def out= out
      @out = out
    end

    # give the configuration a list of files to match
    def files= files
      @files = files
    end

    def configuration= conf
      @configuration = conf
    end

    def opts
      Map.new bundler: @bundler,
              files: @files,
              out: @out,
              configuration: @configuration
    end
  end

  class CpackAppSpec::Task
    include ::Albacore::Logging
    include ::Albacore::CrossPlatformCmd

    # create a new task instance with the given opts
    def initialize opts
      raise ArgumentError, 'opts is nil' if opts.nil?
      @opts = opts
    end

    def execute
      warn 'executing cpack app spec task, but there are no input files [cpack_app_spec::task#execute]' if
        @opts.get(:files).empty?

      cpack_package @opts.get(:out),
                    @opts.get(:files),
                    @opts.get(:configuration)
    end

    private
    def cpack_package out, appspecs, configuration
      appspecs.
        map { |path| Albacore::AppSpec.load path }.
        each do |spec|
          nuspec = create_nuspec spec
          debug { nuspec }
          create_cpack out, spec, nuspec, configuration
      end
    end

    def git_release_notes
      tags = `git tag`.split(/\n/).
                map { |tag| [ ::XSemVer::SemVer.parse_rubygems(tag), tag ] }.
                sort { |a, b| a <=> b }.
                map { |_, tag| tag }
      last_tag = tags[-1]
      second_last_tag = tags[-2] || `git rev-list --max-parents=0 HEAD`
      logs = `git log --pretty=format:%s #{second_last_tag}..`.split(/\n/)
      "Release Notes for #{last_tag}:
#{logs.inject('') { |state, line| state + "\n * #{line}" }}"
    end

    def create_nuspec app_spec
      require 'albacore/nuget_model'
      p = Albacore::NugetModel::Package.new
      p.with_metadata do |m|
        m.id            = app_spec.id
        m.title         = app_spec.title_raw
        m.version       = app_spec.version
        m.authors       = app_spec.authors
        m.owners        = app_spec.owners
        m.description   = app_spec.description || app_spec.title_raw
        m.release_notes = app_spec.release_notes || git_release_notes
        m.summary       = app_spec.summary
        m.language      = app_spec.language
        m.project_url   = app_spec.project_url || 'https://haf.se'
        m.icon_url      = app_spec.icon_url || 'https://haf.se/spacer.gif'
        m.license_url   = app_spec.license_url || 'https://haf.se'
        m.copyright     = app_spec.copyright || 'See Authors'
        m.tags          = app_spec.tags
      end
      p.to_xml
    end

    # create a chocolatey install script for a topshelf service on windows
    def create_chocolatey_install out, service_dir, exe, app_spec
      tools = "#{out}/#{app_spec.id}/tools"

      FileUtils.mkdir tools unless Dir.exists? tools
      File.open(File.join(tools, 'chocolateyInstall.ps1'), 'w+') do |io|
        contents = embedded_resource '../../resources/chocolateyInstall.ps1'
        io.write contents
        io.write %{
Install-Service `
  -ServiceExeName "#{exe}" -ServiceDir "#{service_dir}" `
  -CurrentPath (Split-Path $MyInvocation.MyCommand.Path)
}
      end
    end

    def create_cpack out, app_spec, nuspec_xml, configuration
      target = "#{out}/#{app_spec.id}"
      bin = "#{target}/bin"

      # create target
      FileUtils.mkdir_p target

      # write nuspec
      File.open("#{target}/#{app_spec.id}.nuspec", 'w+') { |io| io.write nuspec_xml }

      # write tools
      create_chocolatey_install out,
                                app_spec.exe,
                                "#{app_spec.target_root_dir}\\#{app_spec.id}",
                                app_spec

      # copy contents of package
      proj_path = File.join(app_spec.proj.proj_path_base,
                            app_spec.proj.output_path(configuration), '.').
                    gsub(/\//, '\\')
      FileUtils.cp_r proj_path, bin, :verbose => true

      # package it
      Dir.chdir target do
        system 'cpack'
      end

      # publish it
      Albacore.publish :artifact, OpenStruct.new(:location => "#{target}/*.nupkg")
    end

    def embedded_resource relative_path
      File.open(embedded_resource_path(relative_path), 'r') { |io| io.read }
    end

    def embedded_resource_path relative_path
      File.join(File.dirname(File.expand_path(__FILE__)), relative_path)
    end
  end
end
