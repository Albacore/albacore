# encoding: utf-8

require 'spec_helper'
require 'shared_contexts'
require 'support/sh_interceptor'
require 'albacore'
require 'albacore/task_types/sql_cmd'

describe 'build config' do
  subject do
    Albacore::Sql::Config.new
  end

  describe 'when setting #server' do
    it 'should be set to a string' do
      subject.server = '.'
      expect(subject.server).to be_a String
    end
  end

  describe 'when setting #database' do
    it 'should be set to a string' do
      subject.database = 'msdb'
      expect(subject.database).to be_a String
    end
  end

   describe 'when setting #trusted_connection' do
     it 'should be set to a Set' do
       subject.trusted_connection
       expect(subject.trusted_connection).to be_a Set
     end
   end

   describe 'when setting #username' do
    it 'should be set to a string' do
      subject.username = 'test'
      expect(subject.username).to be_a String
    end
  end

  describe 'when setting #password' do
    it 'should be set to a string' do
      subject.password = 'test'
      expect(subject.password).to be_a String
    end
  end
end

describe 'when running with sql' do
  let :cfg do
    Albacore::Sql::Config.new
  end

  include_context 'path testing'

  let(:cmd) do
    cmd = Albacore::Sql::Cmd.new cfg.work_dir, 'sqlcmd', cfg.parameters
    cmd.extend ShInterceptor
  end

  before do
    cfg.server = '.'
    cfg.database = 'master'
    cfg.trusted_connection
    cfg.scripts = ["testdata/sqlscript.sql"]
    cfg.exe = "testdata/sqlcmd/sqlcmd.exe"
    cmd.execute
  end

  subject do
    cmd
  end

  it do
    expect(subject.executable).to eq('sqlcmd')
  end
  it do
    expect(subject.parameters).to eq(%W|-S. -dmaster -E|)
  end
  it do
    expect(subject.is_mono_command?).to be false
  end
end