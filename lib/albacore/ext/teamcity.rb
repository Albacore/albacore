require 'albacore'

module Albacore
  module Ext
    # The teamcity module writes appropriate build-script "interaction messages"
    # (see http://confluence.jetbrains.com/display/TCD7/Build+Script+Interaction+with+TeamCity#BuildScriptInteractionwithTeamCity-artPublishing)
    # to STDOUT.
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
      def self.escape message
        message.gsub(/([\[|\]|\|'])/, '|\1').gsub(/\n/, '|n').gsub(/\r/, '|r')
      end
      def self.configure
        Albacore.subscribe :artifact do |artifact|
          ::Albacore.puts "##teamcity[publishArtifacts '#{artifact.location}']"
        end
        Albacore.subscribe :build_version do |version|
          # tell teamcity our decision
          ::Albacore.puts "##teamcity[buildNumber '#{version.build_version}']"
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
