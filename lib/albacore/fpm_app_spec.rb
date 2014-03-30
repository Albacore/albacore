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
#        '--package'     => @out # TODO: figure out how to represent the package
                                 #       name
      }.merge(overrides).reject { |_, v| v.nil? }
    end

    # Generates the flags and flatten them to an array that is possible to feed
    # into the #system command
    #
    def generate_flags_flat overrides = {}
      generate_flags(overrides).map { |k, v| [k, v] }.flatten.push '--force'
    end

    # Calls FPM with the flags generated
    def generate
      ::Albacore::CrossPlatformCmd.system 'fpm', generate_flags_flat
    end
  end
end
