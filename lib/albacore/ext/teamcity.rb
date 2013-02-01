require 'albacore'

module Albacore
  module Ext
    module TeamCity
      def self.configure
        Albacore.subscribe :artifact do |artifact|
          puts "##teamcity[publishArtifacts '#{artifact[:nupkg]}']"
        end
      end
    end
  end
end

Albacore::Ext::TeamCity.configure