require 'albacore'
require 'xsemver'

module Albacore::Tools
  # Try to get the release notes from git, but looking at the commit messages
  def self.git_release_notes
    tags = `git tag`.split(/\n/).
              map { |tag| [ ::XSemVer::SemVer.parse_rubygems(tag), tag ] }.
              sort { |a, b| a <=> b }.
              map { |_, tag| tag }
    last_tag = tags[-1]
    second_last_tag = tags[-2] || `git rev-list --max-parents=0 HEAD`
    logs = `git log --pretty=format:%s #{second_last_tag}..`.split(/\n/)
    "Release Notes for #{last_tag}:
#{logs.inject('') { |state, line| state + "\n * #{line}" }}"
  end
end
