# encoding: utf-8

require 'spec_helper'
require 'shared_contexts'
require 'support/sh_interceptor'
require 'albacore'
require 'albacore/task_types/sql_package'

describe 'build config' do
  subject do
    Albacore::SqlPackage::Config.new
  end

  describe 'when setting #action' do
    it 'should be set to a string' do
      subject.action = 'Publish'
      expect(subject.action).to be_a String
    end
  end

  describe 'when setting #sql_package' do
    it 'should be set to a string' do
      subject.sql_package = 'testdata/test.dacpac'
      expect(subject.sql_package).to be_a String
    end
  end

  describe 'when setting #profile' do
    it 'should be set to a string' do
      subject.profile = '.'
      expect(subject.profile).to be_a String
    end
  end

   describe 'when setting #verify_deployment' do
     it 'should be set to a Set' do
       subject.verify_deployment
       expect(subject.verify_deployment).to be_a Set
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
    Albacore::SqlPackage::Config.new
  end

  include_context 'path testing'

  let(:cmd) do
    cmd = Albacore::SqlPackage::Cmd.new cfg.work_dir, 'SqlPackage', cfg.parameters
    cmd.extend ShInterceptor
  end

  before do
    cfg.action = 'Publish'
    cfg.sql_package = 'testdata/test.dacpac'
    cfg.profile = 'testdata/test.publish'
    cfg.verify_deployment
    cfg.be_quiet
    cmd.execute
  end

  subject do
    cmd
  end

  it do
    expect(subject.executable).to eq('SqlPackage')
  end
  it do
    expect(subject.parameters).to eq(%W|/Action:Publish /SourceFile:testdata/test.dacpac /Profile:testdata/test.publish /p:VerifyDeployment:True /Quiet:True|)
  end
  it do
    expect(subject.is_mono_command?).to be false
  end
end