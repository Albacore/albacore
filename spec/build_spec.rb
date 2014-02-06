require 'spec_helper'
require 'support/sh_interceptor'
require 'albacore'
require 'albacore/task_types/build'

describe 'build config' do
  subject do
    Albacore::Build::Config.new
  end
  %w[file= sln= target target= logging logging= prop cores cores= tools_version tools_version=].each do |writer|
    it "should have property :#{writer}" do
      subject.respond_to?(:"#{writer}").should be_true
    end
  end
  it 'should not have any property' do
    subject.respond_to?(:something_nonexistent).should be_false
  end

  describe 'when setting properties' do
    before do
      subject.logging = 'minimal'
      subject.tools_version = '3.5'
    end
    it do
      subject.parameters.should include('/verbosity:minimal')
      subject.parameters.should include('/toolsversion:3.5')
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
    subject.executable.should eq('xbuild')
  end
  it do
    subject.parameters.should eq(%W|/verbosity:minimal #{path 'src/HelloWorld.sln'} /target:Clean;Build|)
  end
  it do
    subject.is_mono_command?.should be_false
  end
end

