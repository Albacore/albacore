require 'xsemver'
require 'albacore/logging'

module Albacore
  module Tasks

    # Versionizer does versioning ITS OWN WAY!
    #
    # Defines ENV vars:
    #  * BUILD_VERSION
    #  * NUGET_VERSION
    #  * FORMAL_VERSION
    #
    # Publishes symbol :build_version
    module Versionizer

      # adds a new task with the given symbol to the Rake/Albacore application
      # You can use this like any other albacore method, such as build,
      # in order to give it parameters or dependencies, but there is no
      # configuration object that you can configure. Copy-n-paste this
      # code if you want something of your own.
      #
      def self.new *sym
        ver = XSemVer::SemVer.find
        ver.patch = (ENV['BUILD_NUMBER'] || ver.patch).to_i
        version_data = versions(ver, &method(:commit_data))

        Albacore.subscribe :build_version do |data|
          ENV['BUILD_VERSION']  = data.build_version
          ENV['NUGET_VERSION']  = data.nuget_version
          ENV['FORMAL_VERSION'] = data.formal_version
          ENV['LONG_VERSION']   = data.long_version
        end

        Albacore.define_task(*sym) do
          Albacore.publish :build_version, OpenStruct.new(version_data)
        end
      end

      def self.versions semver, &commit_data
        {
          # just a monotonic inc
          :build_number   => semver.patch,
          :semver         => semver,

          # purely M.m.p format
          :formal_version => "#{ XSemVer::SemVer.new(semver.major, semver.minor, semver.patch).format "%M.%m.%p"}",

          # four-numbers version, useful if you're dealing with COM/Windows
          :long_version   => "#{semver.format '%M.%m.%p'}.0",

          # extensible number w/ git hash
          :build_version  => semver.format("%M.%m.%p%s") + ".#{yield[0]}",

          # nuget (not full semver 2.0.0 support) see http://nuget.codeplex.com/workitem/1796
          :nuget_version  => format_nuget(semver)
        }
      end

      def self.format_nuget semver
        if semver.prerelease
          "#{semver.major}.#{semver.minor}.#{semver.patch}-#{semver.prerelease.gsub(/\W/, '')}"
        else
          semver.format '%M.%m.%p'
        end
      end

      # load the commit data
      # returns: [short-commit :: String, date :: DateTime]
      #
      def self.commit_data
        begin
          commit = `git rev-parse --short HEAD`.chomp()[0,6]
          git_date = `git log -1 --date=iso --pretty=format:%ad`
          commit_date = DateTime.parse( git_date ).strftime("%Y-%m-%d %H:%M:%S")
        rescue
          commit = (ENV['BUILD_VCS_NUMBER'] || "000000")[0,6]
          commit_date = Time.new.strftime("%Y-%m-%d %H:%M:%S")
        end
        [commit, commit_date]
      end
    end
  end
end
