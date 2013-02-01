require 'albacore'

module Albacore
  module Ext
    # The teamcity module writes appropriate build-script "interaction messages"
    # (see http://confluence.jetbrains.com/display/TCD7/Build+Script+Interaction+with+TeamCity#BuildScriptInteractionwithTeamCity-artPublishing)
    # to STDOUT.
    module TeamCity
      def self.configure
        Albacore.subscribe :artifact do |artifact|
          puts "##teamcity[publishArtifacts '#{artifact[:nupkg]}']"
        end
        Albacore.subscribe :build_version do |version|
          # tell teamcity our decision
          puts "##teamcity[buildNumber '#{version.build_version}']"
        end
      end
    end
  end
end

# subscribe the handlers directly when loading this file
Albacore::Ext::TeamCity.configure