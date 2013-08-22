require 'spec_helper'
require 'support/sh_interceptor'
require 'albacore'
require 'albacore/task_types/build'

shared_context 'config' do
  let(:cfg) do
    Albacore::Build::Config.new
  end
end

describe 'when running with sln' do

  include_context 'config'
  include_context 'path testing'

  let(:cmd) do
    cmd = Albacore::Build::Cmd.new cfg.work_dir, 'xbuild', cfg.parameters
    cmd.extend ShInterceptor
  end

  before do
    cfg.sln = 'src/HelloWorld.sln'
    cmd.execute
  end

  subject do
    cmd
  end

  it { subject.executable.should eq('xbuild') }
  it { subject.parameters.should eq(%W|/verbosity:minimal #{path 'src/HelloWorld.sln'}|) }
  it { subject.is_mono_command?.should be_false }
end
