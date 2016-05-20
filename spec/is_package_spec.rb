# encoding: utf-8

require 'spec_helper'
require 'shared_contexts'
require 'support/sh_interceptor'
require 'albacore'
require 'albacore/task_types/is_package'

describe 'build config' do
  subject do
    Albacore::IsPackage::Config.new
  end

  describe 'when setting #is_package' do
    it 'should be set to a string' do
      subject.is_package = 'testdata/test.ispac'
      expect(subject.is_package).to be_a String
    end
  end

  describe 'when setting #server' do
    it 'should be set to a string' do
      subject.server = '.'
      expect(subject.server).to be_a String
    end
  end

  describe 'when setting #database' do
    it 'should be set to a string' do
      subject.database = '.'
      expect(subject.database).to be_a String
    end
  end

  describe 'when setting #folder_name' do
    it 'should be set to a string' do
      subject.folder_name = '.'
      expect(subject.folder_name).to be_a String
    end
  end

  describe 'when setting #project_name' do
    it 'should be set to a string' do
      subject.project_name = 'test'
      expect(subject.project_name).to be_a String
    end
  end

   describe 'when setting #be_quiet' do
     it 'should be set to a Set' do
       subject.be_quiet
       expect(subject.be_quiet).to be_a Set
     end
   end
end

describe 'when running with sql' do
  let :cfg do
    Albacore::IsPackage::Config.new
  end

  include_context 'path testing'

  let(:cmd) do
    cmd = Albacore::IsPackage::Cmd.new cfg.work_dir, 'ISDeploymentWizard', cfg.parameters
    cmd.extend ShInterceptor
  end

  before do
    cfg.be_quiet
    cfg.is_package = 'testdata/test.ispac'
    cfg.server = '.'
    cfg.database = 'SSISDB'
    cfg.folder_name = 'test'
    cfg.project_name = 'test'
    cfg.get_parameters
    cmd.execute
  end

  subject do
    cmd
  end

  it do
    expect(subject.executable).to eq('ISDeploymentWizard')
  end
  it do
    expect(subject.parameters).to eq(%W|/Silent /SourcePath:testdata/test.ispac /DestinationServer:. /DestinationPath:/SSISDB/test/test|)
  end
  it do
    expect(subject.is_mono_command?).to be false
  end
end