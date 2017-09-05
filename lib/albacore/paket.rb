require 'ostruct'
require 'albacore/semver'

module Albacore
  module Paket
    def self.parse_lock_line line
      if (m = line.match(/^\s*(?<id>[\w\-\.]+) \((?<ver>[\.\d\w\-]+)\)( - )?((framework: >= (?<tf>\w+))|(redirects: (?<redir>\w+)))?$/i))
        ver = Albacore::SemVer.parse(m[:ver], '%M.%m.%p', false)
        OpenStruct.new(:id               => m[:id],
                       :version          => m[:ver],
                       :group            => true,
                       :target_framework => m[:tf],
                       :redirects        => m[:redir] || nil,
                       :semver           => ver)
      end
    end

    # returns [id, {id,version,group,target_framework,redirects,semver}][]
    def self.parse_paket_lock data
      data.map { |line| parse_lock_line line }
          .compact
          .map { |package| [package.id, package] }
    end

    # returns string or nil
    def self.parse_dependencies_line line
      if (m = line.match(/^nuget (?<id>[\w\-\.]+)$/i))
        m[:id]
      end
    end

    # returns a string[]
    def self.parse_dependencies_file data
      data.map { |line| parse_dependencies_line line }
          .compact
    end
  end
end
