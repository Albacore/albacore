require 'spec_helper'
require 'albacore'
require 'albacore/task_types/nugets_restore'
require 'albacore/dsl'
require 'support/sh_interceptor'

class NGConf
  self.extend Albacore::DSL 
end

shared_context 'cmd context' do
  let (:hafsrc) { OpenStruct.new(:name => 'haf-source', :uri => 'https://haf.se/nugets') }
  before(:each) { cmd.extend ShInterceptor }
  subject { cmd.execute ; cmd.mono_parameters }
end

describe Albacore::NugetsRestore::Config, 'when setting #source' do
  it 'should allow setting a string' do
    subject.source = 'hello'
    expect(subject.source).not_to be_a String
    expect(subject.source).to be_a OpenStruct
    expect(subject.source.name).to eq(Digest::MD5.hexdigest('hello'))
  end
  it 'should allow setting an OpenStruct' do
    subject.source = OpenStruct.new :name => 'a', :uri => 'https://example.com/nugetfeed.svc'
    expect(subject.source).not_to be_a String
    expect(subject.source).to be_a OpenStruct
    expect(subject.source.name).to eq 'a'
    expect(subject.source.uri).to eq 'https://example.com/nugetfeed.svc'
  end
end

describe Albacore::NugetsRestore::RemoveSourceCmd, 'when calling #execute should remove source' do
  let(:cmd) { Albacore::NugetsRestore::RemoveSourceCmd.new 'nuget.exe', hafsrc }
  include_context 'cmd context'
  %w[remove sources -name haf-source].each { |k|
    it { should include(k) }
  }
end

describe Albacore::NugetsRestore::AddSourceCmd, 'when calling #execute should remove source' do
  let (:cmd) { Albacore::NugetsRestore::AddSourceCmd.new 'nuget.exe', hafsrc, 'u', 'p' }
  include_context 'cmd context'
  %w[sources add -name haf-source].each { |k|
    it { should include(k) }
  }
end

describe Albacore::NugetsRestore::Cmd, 'when calling #execute with specific source' do
  let (:cmd) do
    cfg = Albacore::NugetsRestore::Config.new
    cfg.out = 'src/packages'
    cfg.add_parameter '-Source' 
    cfg.add_parameter 'http://localhost:8081'

    cmd = Albacore::NugetsRestore::Cmd.new nil, 'NuGet.exe', cfg.opts_for_pkgcfg('src/Proj/packages.config')
  end

  let (:path) do
    Albacore::Paths.normalise_slashes('src/Proj/packages.config')
  end

  include_context 'cmd context'

  %W[install -OutputDirectory src/packages -Source http://localhost:8081].each { |parameter|
    it { should include(parameter) }
  }
  it { should include(path) }
end 
