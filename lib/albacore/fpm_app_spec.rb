require 'albacore/app_spec'
require 'map'

module Albacore
  class InvalidAppSpecError < ::StandardError
  end

  # An object that is capable of generating FPM commands - use by giving it a
  # spec and then calling #execute or #generate_flags. You may use this object
  # to package a directory.
  #
  class FpmAppSpec
    include ::Albacore::Logging

    # Initialize the object with an ::Albacore::AppSpec
    #
    # @param [::Albacore::AppSpec] app_spec The required package metadata.
    # @param [PathWrap, String] output_dir_path The output path of the rpm/deb
    #                                           package.
    def initialize app_spec, output_dir_path = '.'
      raise ArgumentError, 'missing app_spec parameter' unless app_spec
      @spec = app_spec
      @out  = output_dir_path
    end

    # Generate flags for FPM - if you don't want to execute directly with the object
    # you can use this method to generate what you should give to FPM yourself
    #
    def generate_flags overrides = {}
      { '-s'            => 'dir',
        '-t'            => 'rpm',
        '--name'        => @spec.title,
        '--description' => @spec.description,
        '--url'         => @spec.uri,
        '--category'    => @spec.category,
        '--version'     => @spec.version,
        '--epoch'       => 1,
        '--license'     => @spec.license,
        '-C'            => @spec.dir_path,
        '--depends'     => 'mono',
        '--rpm-digest'  => 'sha256',
        '--package'     => @out
      }.merge(overrides).reject { |_, v| v.nil? }
    end

    # Generates the flags and flatten them to an array that is possible to feed
    # into the #system command
    #
    def generate_flags_flat overrides = {}
      generate_flags(overrides).map { |k, v| [k, v] }.concat(%w|--force .|).flatten
    end

    # gets the filename that the resulting file will have, based on the flags
    # to be passed to fpm
    def filename flags = nil
      flags ||= generate_flags
      # TODO: handle OS architecture properly by taking from context
      "#{flags['--name']}-#{flags['--version']}-#{flags['--epoch']}.x86_64.rpm"
    end

    # Calls FPM with the flags generated
    def generate
      ::Albacore::CrossPlatformCmd.system 'fpm', generate_flags_flat
    end
  end

  class FpmAppSpec::Config
    # create a new configuration for multiple xxproj-s to be packed with fpm into .deb/.rpm
    def initialize
      @bundler = true
      @files   = []
      @out     = '.'
    end

    # turn off the using of bundler; bundler will be used by default
    def no_bundler
      @bundler = false
    end

    # set the output path, defaults to '.'
    def out= out
      @out = out
    end

    # give the configuration a list of files to match
    def files= files
      @files = files
    end

    def opts
      Map.new bundler: @bundler,
              files: @files,
              out: @out
    end
  end

  # task implementation that can be #execute'd
  class FpmAppSpec::Task
    include ::Albacore::Logging
    include ::Albacore::CrossPlatformCmd

    # create a new task instance with the given opts
    def initialize opts
      raise ArgumentError, 'opts is nil' if opts.nil?
      @opts = opts
    end

    # this runs fpm and does some file copying
    def execute
      warn 'executing fpm app spec task, but there are no input files [fpm_app_spec::task#execute]' if
        @opts.get(:files).empty?

      fpm_package @opts.get(:out), @opts.get(:files)
    end

    private
    def fpm_package out, appspecs
      pkg = File.join out, 'pkg'

      appspecs.
        map { |path| Albacore::AppSpec.load path }.
        map { |as| [as, Albacore::FpmAppSpec.new(as, pkg)] }.
        each do |spec, fpm|
        targ = "#{out}/#{spec.title}/tmp-dest/"
        FileUtils.mkdir_p targ

        bin = File.join targ, "opt/#{spec.title}/bin"
        FileUtils.mkdir_p bin
        FileUtils.cp_r Dir.glob(File.join(fpm_rel(spec, spec.bin_folder), '*')),
                       bin, verbose: true

        etc = File.join targ, "etc/#{spec.title}"
        FileUtils.mkdir_p etc, verbose: true
  #      FileUtils.cp_r Dir.glob(File.join(fpm_rel(spec, spec.conf_folder), '*')),
  #                     etc, verbose: true

        spec.contents.each do |con|
          FileUtils.cp_r fpm_rel(spec, con), File.join(targ, con), verbose: true
        end

        run fpm.generate_flags_flat({ '-C' => targ })
      end
    end


    def fpm_rel spec, path
      File.join spec.dir_path, path
    end

    def run pars
      if @opts.get :bundle
        system 'bundle', %w|exec fpm|.concat(pars)
      else
        system 'fpm', pars
      end
      Albacore.publish :artifact, OpenStruct.new({ :location => "#{pkg}/#{fpm.filename}" })
    end
  end
end
