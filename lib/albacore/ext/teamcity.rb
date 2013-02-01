require 'albacore'

module Albacore
  module Ext
    module TeamCity
      def self.configure
        Albacore.subscribe :artifact do |artifact|
          puts "##teamcity[publishArtifacts '#{artifact[:nupkg]}']"
        end
        Albacore.subscribe :build_version do |version|
          # tell teamcity our decision
          puts %Q[##teamcity[buildNumber '#{ENV["BUILD_VERSION"]}']]
        end

      end
    end
  end
end

Albacore::Ext::TeamCity.configure