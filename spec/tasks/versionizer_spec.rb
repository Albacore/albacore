require 'albacore'
require 'albacore/tasks/versionizer'
require 'xsemver'

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

describe 'finding build special versions' do
  subject do
    ver = XSemVer::SemVer.new(1, 2, 3, 'deadbeef')
    ::Albacore::Tasks::Versionizer.versions ver do
      ['123456', '2014-02-27 16:55:55']
    end
  end

  it 'should return a hash' do
    subject.should be_a(Hash)
  end

  it 'should return the correct build number' do
    subject[:build_number].should eq(3)
  end

  it 'should return the same semver' do
    subject[:semver].should eq(::XSemVer::SemVer.new(1, 2, 3, 'deadbeef'))
  end

  it 'should return the correct long_version' do
    subject[:long_version].should eq('1.2.3.0')
  end

  it 'should return the correct formal_version' do
    subject[:formal_version].should eq('1.2.3')
  end

  it 'should return a build_version' do
    subject[:build_version].should_not be_nil
  end

  it 'should return a build_version with correct hash/special substring' do
    subject[:build_version].should eq('1.2.3-deadbeef.123456')
  end

  it 'should return a nuget_version' do
    expect(subject[:nuget_version]).to_not be nil
  end

  it 'should return a proper semver nuget version' do
    expect(subject[:nuget_version]).to eq '1.2.3-deadbeef'
  end
end

describe 'finding build versions' do
  subject do
    ver = XSemVer::SemVer.new(1, 2, 3, 'alpha.1-wasabi')
    ::Albacore::Tasks::Versionizer.versions ver do
      ['123456', '2014-02-27 16:55:55']
    end
  end

  it 'should return a nuget_version' do
    expect(subject[:nuget_version]).to_not be nil
  end

  it 'should not return the proper semver 2.0 format' do
    # nuget doesn't support semver 2.0
    expect(subject[:nuget_version]).to eq '1.2.3-alpha1wasabi'
  end
end

describe 'finding build special versions' do
  subject do
    ver = XSemVer::SemVer.new(1, 2, 3)
    ::Albacore::Tasks::Versionizer.versions ver do
      ['123456', '2014-02-27 16:55:55']
    end
  end

  it 'should not return the proper semver 2.0 format' do
    # nuget doesn't support semver 2.0
    expect(subject[:nuget_version]).to eq '1.2.3'
  end
end
