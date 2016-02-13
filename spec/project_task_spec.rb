# encoding: utf-8

require 'spec_helper'
require 'shared_contexts'
require 'support/sh_interceptor'
require 'albacore'
require 'albacore/task_types/nugets_pack'
require 'albacore/nuget_model'

include ::Albacore::NugetsPack

describe ProjectTask do
  include_context 'pack_config no symbols'
  include_context 'package_metadata_dsl'

  it 'sanity: should have config with target=mono32' do
    expect(config.opts().get(:target)).to eq('mono32')
  end

  let :projfile do
    curr = File.dirname(__FILE__)
    File.join curr, "testdata", "Project", "Project.fsproj"
  end

  subject do
    proj = Albacore::Project.new projfile
    ProjectTask.new( config.opts() ).send(:create_nuspec, proj, [])[0] # index0 first nuspec Alabacore::Package
  end

  has_file 'bin/Debug/Project.dll', 'lib/mono32'
end

describe ProjectTask, "when testing public interface" do
  let :projfile do
    curr = File.dirname(__FILE__)
    File.join curr, "testdata", "Project.fsproj"
  end
  it "can be created" do
    ProjectTask.new(Map.new(:files => [projfile]))
  end
  it "rejects .nuspec files" do
    expect(ProjectTask.accept?('some.nuspec')).to eq false
  end
end

describe ProjectTask, "creating nuget from proj file" do
  let(:cmdo) { Hash.new }

  subject do
    ProjectTask.new(config.opts()) do |cmd|
      cmd.extend ShInterceptor
      cmdo[:cmd] = cmd
    end
  end

  before :each do
    subject.execute
  end

  describe 'when generating symbols' do
    include_context 'pack_config'
    it 'should have generated a nuspec' do
      expect(cmdo[:cmd].mono_parameters(0)[-1]).to include('Sample.Nuget.nuspec')
    end
    it 'should have generated a symbol nuspec' do
      expect(cmdo[:cmd].mono_parameters(1)[-1]).to include('Sample.Nuget.symbols.nuspec')
    end
  end

  describe 'when not generating symbols' do
    include_context 'pack_config no symbols'
    it 'should have generated a nuspec' do
      expect(cmdo[:cmd].mono_parameters(0)[-1]).to include('Sample.Nuget.nuspec')
    end
    it 'should have done no further calls' do
      expect(cmdo[:cmd].invocations.length).to eq(1)
    end
    it 'should have no further invocations' do
      begin
        cmdo[:cmd].mono_parameters(1)
      rescue RuntimeError
      end
    end
  end
end
describe ProjectTask, "path_to should accept both relative and absolute paths" do
  let :proj_task do
    curr = File.dirname(__FILE__)
    ProjectTask.new(Map.new(
      :files => [File.join( curr, "testdata", "Project.fsproj")],
      :original_path => "/original_path/"))
  end
  it "should use original_path to resolve path" do
    expect(proj_task.path_to( "./bin/something.exe", "./tmp/")).to eq "/original_path/bin/something.exe"
  end
  it "should return the absolute path when the path to the exe is absolute" do
    expect(proj_task.path_to( "/bin/something.exe", "./tmp/")).to eq "/bin/something.exe"
  end
end
