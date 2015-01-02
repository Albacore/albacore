require 'albacore/tools'
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
        m.release_notes = app_spec.release_notes || Albacore::Tools.git_release_notes
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

    def create_cpack out, app_spec, nuspec_xml, configuration
      provider = find_provider app_spec

      target = "#{out}/#{app_spec.id}"
      contents = "#{target}/#{provider.nuget_contents}/"

      debug { 'create target [cpack_app_spec#create_cpack]' }
      FileUtils.mkdir_p target

      debug { 'write nuspec [cpack_app_spec#create_cpack]' }
      File.open("#{target}/#{app_spec.id}.nuspec", 'w+') { |io| io.write nuspec_xml }

      debug { 'write tools/chocolateyInstall.ps1 [cpack_app_spec#create_cpack]' }
      provider.install_script out, app_spec

      debug { 'copy contents of package [cpack_app_spec#create_cpack]' }
      FileUtils.cp_r provider.source_dir(app_spec, configuration),
                     contents,
                     :verbose => true

      # package it
      Dir.chdir target do
        system 'cpack'
      end

      # publish it
      Albacore.publish :artifact, OpenStruct.new(
        :location => "#{target}/#{app_spec.id}.#{app_spec.version}.nupkg"
      )
    end

    def find_provider app_spec
      require "albacore/app_spec/#{app_spec.provider}"
      case app_spec.provider
      when 'defaults'
        AppSpec::Defaults.new
      when 'iis_site'
        AppSpec::IisSite.new
      else
        raise ArgumentError, "unknown app_spec.provider: #{app_spec.provider}"
      end
    end
  end
end
