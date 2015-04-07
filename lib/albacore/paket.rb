require 'ostruct'
require 'albacore/semver'

module Albacore
  module Paket
    def parse_line line
      if (m = line.match /^\s*(?<id>[\w\-\.]+) \((?<ver>[\.\d\w\-]+)\)$/i)
        ver = Albacore::SemVer.parse(m[:ver], '%M.%m.%p', false)
        OpenStruct.new(:id               => m[:id],
                       :version          => m[:ver],
                       :target_framework => 'net40',
                       :semver           => ver)
      end
    end

    def parse_paket_lock data
      data.map { |line| parse_line line }.
           compact.
           map { |package| [package.id, package] }
    end
  end
end
