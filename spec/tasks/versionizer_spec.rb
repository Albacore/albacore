require 'albacore'
require 'albacore/tasks/versionizer'

describe 'adding versionizer to a class' do
  class VersioniserUsage
    def initialize
      ::Albacore::Tasks::Versionizer.new :v
    end
  end

  it 'can create a new class instance' do
    begin
      VersioniserUsage.new
    rescue SemVerMissingError
    end
  end
end

describe 'finding build versions'
  subject do
    ::Albacore::Tasks::Versionizer.versions
  end

  it do
    subject...
  end
end

