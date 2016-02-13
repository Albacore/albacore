require 'rake'
require 'nokogiri'
require 'albacore/paths'
require 'albacore/cmd_config'
require 'albacore/cross_platform_cmd'
require 'albacore/nugets'
require 'albacore/task_types/nugets_authentication'

module Albacore
  module NugetsRestore

    class RemoveSourceCmd
      include Logging
      include CrossPlatformCmd
      def initialize exe, source
        @executable = exe
        @parameters = %W[sources remove -name #{source.name} -source #{source.uri}]
        mono_command
      end
      def execute
        system @executable, @parameters, :verbose => true do |ok, status|
          ok
        end
      end
    end

    class AddSourceCmd
      include Logging
      include CrossPlatformCmd
      def initialize exe, source, user, pass
        @executable = exe
        @parameters = %W[sources add -name #{source.name} -source #{source.uri} -user #{user} -password #{pass}] 
        mono_command
      end
      def execute
        system @executable, @parameters, :ensure_success => true
      end
    end

    class Cmd
      include Logging
      include CrossPlatformCmd

      def initialize work_dir, executable, *args
        opts = Map.options args
        raise ArgumentError, 'pkgcfg is nil' if opts.getopt(:pkgcfg).nil? 
        raise ArgumentError, 'out is nil' if opts.getopts(:out).nil?
        @work_dir = work_dir
        @executable = executable
        @opts = opts

        pars = opts.getopt(:parameters, :default => [])
        @parameters = [%W{install #{opts.getopt(:pkgcfg)} -OutputDirectory #{opts.getopt(:out)}}, pars.to_a].flatten

        mono_command
      end

      def execute
        system @executable, @parameters, :work_dir => @work_dir, :output => false
      end
    end

    # Public: Configure 'nuget.exe install' -- nuget restore.
    #
    # work_dir - optional
    # exe - required NuGet.exe path
    # out - required location of 'packages' folder
    class Config
      include CmdConfig # => :exe, :work_dir, @parameters, #add_parameter
      include NugetsAuthentication # => :username, :password
      include Logging

      OFFICIAL_REPO = 'https://nuget.org/api/v2/'

      # Create a new Config object
      def initialize
        @include_official = false
        @list_spec = File.join '**', 'packages.config'
      end

      # the output directory passed to nuget when restoring the nugets
      attr_writer :out

      # nuget source, when other than MSFT source
      def source
        @source
      end

      # set the nuget source
      def source= val
        if val.is_a? String
          debug { 'you used a plain string as source, naming it after its md5 digest' }
          md5 = Digest::MD5.hexdigest val
          @source = OpenStruct.new(:name => md5, :uri => val)
        else
          @source = val
        end
      end

      # specifies the list specification to load 'packages.config' files
      # from.
      #
      # e.g. '**/packages.config' on *nix.
      attr_accessor :list_spec

      def packages
        # it seems FileList doesn't care about the curr dir
        in_work_dir do
          FileList[
            Dir.glob(list_spec, File::FNM_DOTMATCH).
              reject { |a| a =~ /^\.{1,2}$/ }
          ]
        end
      end

      # whether to include the official
      # defaults to true
      attr_accessor :include_official

      def exclude_version
        add_parameter "-ExcludeVersion"
      end

      def no_cache
        add_parameter "-NoCache"
      end

      def has_credentials?
        username && password && source
      end

      def ensure_authentication!
        return unless has_credentials?
        remove = RemoveSourceCmd.new exe, source
        readd  = AddSourceCmd.new exe, source, username, password
        remove.execute
        readd.execute
      end

      def nuget_gem_exe
        @exe = Albacore::Nugets::find_nuget_gem_exe
      end

      def opts_for_pkgcfg pkg
        pars = parameters.to_a
        debug "include_official nuget repo: #{include_official}"
        pars << %W[-source #{OFFICIAL_REPO}] if include_official
        
        map = Map.new({ :pkgcfg     => Albacore::Paths.normalise_slashes(pkg),
                        :out        => @out,
                        :parameters => pars })

        if has_credentials?
          map.set :username, username
          map.set :password, password
          map.set :source, source
        end 
        map
      end
    end

    class Task
      def initialize command_line
        @command_line = command_line
      end
      def execute
        @command_line.execute
      end
    end
  end
end
