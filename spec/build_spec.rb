require 'spec_helper'
require 'support/sh_interceptor'
require 'albacore'
require 'albacore/task_types/build'

shared_context 'config' do
  let(:cfg) do
    cfg = Albacore::Build::Config.new
    cfg
  end
end

describe 'when running with sln' do

  include_context 'config'

  let(:cmd) { 
    cmd = Albacore::Build::Cmd.new cfg.work_dir, 'xbuild', cfg.parameters
    cmd.extend ShInterceptor
  }

  before {
    cfg.sln = 'src/HelloWorld.sln'
    cmd.execute
  }

  subject { cmd }

  it { subject.executable.should eq('xbuild') }
  it { subject.parameters.should eq(%W[/verbosity:minimal src/HelloWorld.sln]) }
  it { subject.is_mono_command?().should be_false }
end
