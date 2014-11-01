require 'albacore'
require 'net/http'
require 'uri'

module Albacore
  module Ext

    # The teamcity module writes appropriate build-script "interaction messages"
    # (see http://confluence.jetbrains.com/display/TCD7/Build+Script+Interaction+with+TeamCity#BuildScriptInteractionwithTeamCity-artPublishing)
    # to STDOUT.
    #
    module TeamCity

      # Escaped the progress message
      # (see http://confluence.jetbrains.com/display/TCD7/Build+Script+Interaction+with+TeamCity#BuildScriptInteractionwithTeamCity-ServiceMessages)
      # The Unicode symbol escape is not implemented
      # Character                                  Should be escaped as
      # ' (apostrophe)                             |'
      # \n (line feed)                             |n
      # \r (carriage return)                       |r
      # \uNNNN (unicode symbol with code 0xNNNN)   |0xNNNN
      # | (vertical bar)                           ||
      # [ (opening bracket)                        |[
      # ] (closing bracket)                        |]
      #
      def self.escape message
        message.gsub(/([\[|\]|\|'])/, '|\1').gsub(/\n/, '|n').gsub(/\r/, '|r')
      end

      def self.configure
        Albacore.subscribe :artifact do |artifact|
          ::Albacore.puts "##teamcity[publishArtifacts '#{artifact.location}']"
        end
        Albacore.subscribe :build_version do |version|
          # tell teamcity our decision
          ::Albacore.puts "##teamcity[buildNumber '#{version.build_number}']" # available as 'build.number' in TC
          ::Albacore.puts "##teamcity[setParameter name='build.version' value='#{version.build_version}']"
          ::Albacore.puts "##teamcity[setParameter name='build.version.formal' value='#{version.formal_version}']"
        end
        Albacore.subscribe :progress do |p|
          # tell teamcity of our progress
          ::Albacore.puts "##teamcity[progressMessage '#{escape p.message}']"
        end
        Albacore.subscribe :start_progress do |p|
          # tell teamcity of our progress
          start_progress p.message
        end
        Albacore.subscribe :finish_progress do |p|
          # tell teamcity of our progress
          finish_progress p.message
        end
        Albacore.subscribe :release do |r|
          ::Albacore.puts 'Pinning build'
          # https://stackoverflow.com/questions/12681908/is-it-possible-to-automate-the-teamcity-pin-functionality-on-a-run-custom-build
          uri = URI.parse("%teamcity.serverUrl%/httpAuth/app/rest/builds/id:%teamcity.build.id%/pin -u 'TCuser:TCpass'")
          # curl -v -H "Content-Type:text/plain" -d "Deliverable" %teamcity.serverUrl%/httpAuth/app/rest/builds/id:%teamcity.build.id%/tags -u "TCuser:TCpass"
          http = Net::HTTP.new uri.host, uri.port
          put = Net::HTTP::Put.new uri.request_uri
          #request["Content-Type"] = "application/json"
          response = http.request put
          ::Albacore.puts "Done, server replied #{response.code}"
        end
      end

      private

      PROGRESS_QUEUE = []

      # Starts a new progress block
      def self.start_progress(name)
        PROGRESS_QUEUE.push name
        ::Albacore.puts "##teamcity[progressStart '#{escape name}']"
      end

      # Finishes the progress block and all child progress blocks
      def self.finish_progress(name = '')
        loop do
          p = PROGRESS_QUEUE.pop
          ::Albacore.puts "##teamcity[progressFinish '#{escape p}']" unless p.nil?
          break unless !p.nil? || name == p || name == ''
        end
      end
    end
  end
end

# subscribe the handlers directly when loading this file
Albacore::Ext::TeamCity.configure
