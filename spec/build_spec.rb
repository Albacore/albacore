require 'spec_helper'
require 'support/sh_interceptor'
require 'albacore'
require 'albacore/task_types/build'

describe 'build config' do
  subject do
    Albacore::Build::Config.new
  end
  %w[file= sln= target target= logging logging= prop cores cores= tools_version tools_version=].each do |writer|
    it "should respond to :#{writer}" do
      expect(subject).to respond_to(:"#{writer}")
    end
  end
  it 'should not have any property' do
    expect(subject).to_not respond_to(:something_nonexistent)
  end

  describe 'when setting properties' do
    before do
      subject.logging = 'minimal'
      subject.tools_version = '3.5'
    end
    it do
      expect(subject.parameters).to include('/verbosity:minimal')
      expect(subject.parameters).to include('/toolsversion:3.5')
    end
  end
end

describe 'when running with sln' do
  let :cfg do
    Albacore::Build::Config.new
  end

  include_context 'path testing'

  let(:cmd) do
    cmd = Albacore::Build::Cmd.new cfg.work_dir, 'xbuild', cfg.parameters
    cmd.extend ShInterceptor
  end

  before do
    cfg.sln = 'src/HelloWorld.sln'
    cfg.target = %w|Clean Build|
    cmd.execute
  end

  subject do
    cmd
  end

  it do
    expect(subject.executable).to eq('xbuild')
  end
  it do
    expect(subject.parameters).to eq(%W|/verbosity:minimal #{path 'src/HelloWorld.sln'} /target:Clean;Build|)
  end
  it do
    expect(subject.is_mono_command?).to be false
  end
end

