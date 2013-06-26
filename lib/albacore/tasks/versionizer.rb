require 'semver'
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
        ver = SemVer.find
        revision = (ENV['BUILD_NUMBER'] || ver.patch).to_i
        ver = SemVer.new(ver.major, ver.minor, revision, ver.special)
        
        # extensible number w/ git hash
        ENV['BUILD_VERSION'] = ver.format("%M.%m.%p%s") + ".#{commit_data()[0]}"
        
        # nuget (not full semver 2.0.0-rc.1 support) see http://nuget.codeplex.com/workitem/1796
        ENV['NUGET_VERSION'] = ver.format("%M.%m.%p%s")
        
        # purely M.m.p format
        ENV['FORMAL_VERSION'] = "#{ SemVer.new(ver.major, ver.minor, revision).format "%M.%m.%p"}"
        
        body = proc {
          Albacore.publish :build_version, OpenStruct.new(
            :build_number   => revision,
            :build_version  => ENV['BUILD_VERSION'],
            :semver         => ver,
            :formal_version => ENV['FORMAL_VERSION']
          )
        }

        Albacore.define_task *sym, &body
      end

      # load the commit data
      # returns: [short-commit :: String, date :: DateTime]
      #
      def self.commit_data
        begin
          commit = `git rev-parse --short HEAD`.chomp()[0,6]
          git_date = `git log -1 --date=iso --pretty=format:%ad`
          commit_date = DateTime.parse( git_date ).strftime("%Y-%m-%d %H%M%S")
        rescue Exception => e
          commit = (ENV['BUILD_VCS_NUMBER'] || "000000")[0,6]
          commit_date = Time.new.strftime("%Y-%m-%d %H%M%S")
        end
        [commit, commit_date]
      end
    end
  end
end
