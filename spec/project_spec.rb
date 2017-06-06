require_relative 'spec_helper'
require 'albacore/semver'
require 'albacore/project'
require 'albacore/paths'

describe Albacore::Project, "when loading packages.config" do
  subject do
    p = File.expand_path('../testdata/Project/Project.fsproj', __FILE__)
    #puts "path: #{p}"
    Albacore.create_project(p)
  end
  let :nlog do
    subject.declared_packages.find { |p| p.id == 'NLog' }
  end

  it 'should have a guid' do
    expect(subject.guid).to match /^[A-F0-9]{8}(?:-[A-F0-9]{4}){3}-[A-F0-9]{12}$/i
  end

  it 'assumption: can gsub("[\{\}]", "")' do
    expect('{a}'.gsub(/[\{\}]/, '')).to eq 'a'
  end

  it 'should have an OutputPath' do
    expect(subject.output_path('Debug')).to_not be_nil
  end
  it 'should have the correct OutputPath' do
    expect(subject.output_path('Debug')).to eq('bin\\Debug\\')
  end
  it 'should also have a Release OutputPath' do
    expect(subject.output_path('Release')).to eq('bin\\Release\\')
    expect(subject.try_output_path('Release')).to eq('bin\\Release\\')
  end
  it 'should raise "ConfigurationNotFoundEror" if not found' do
    begin
      subject.output_path('wazaaa')
    rescue ::Albacore::ConfigurationNotFoundError
    end
  end
  it 'should return nil with #try_output_path(conf)' do
    expect(subject.try_output_path('weeeo')).to be_nil
  end
  it "should have three packages" do
    expect(subject.declared_packages.length).to eq 3
  end
  it "should contain NLog" do
    expect(nlog).to_not be_nil
  end
  it "should have a four number on NLog" do
    expect(nlog.version).to eq("2.0.0.2000")
  end
  it "should have a semver number" do
    expect(nlog.semver).to eq(Albacore::SemVer.new(2, 0, 0))
  end
end

describe Albacore::Project, "when reading project file" do
  def project_path
    File.expand_path('../testdata/Project/Project.fsproj', __FILE__)
  end

  subject do
    Albacore.create_project project_path
  end
  let :library1 do
    subject.included_files.find { |p| p.include == 'Library1.fs' }
  end
  it "should contain library1" do
    expect(library1).to_not be_nil
  end
  it 'should contain the target framework' do
    expect(subject.target_framework).to eq "v4.5"
  end
  
  describe 'public API' do
    it do
      expect(subject).to respond_to :name
    end
    it do
      expect(subject).to respond_to :asmname
    end
    it do
      expect(subject).to respond_to :namespace
    end
    it do
      expect(subject).to respond_to :version
    end
    it do
      expect(subject).to respond_to :authors
    end
    it do
      expect(subject).to respond_to :description
    end
    it do
      expect(subject).to respond_to :license
    end
    it do
      expect(subject).to respond_to :target_framework
    end
    it 'should have five referenced assemblies' do
      expect(subject.find_refs.length).to eq 5
    end
    it 'knows about referenced packages' do
      expect(subject).to respond_to :declared_packages
    end
    it 'knows about referenced projects' do
      expect(subject).to respond_to :declared_projects
    end
    it 'should have three referenced packages' do
      expected = %w|Intelliplan.Util Newtonsoft.Json NLog|
      expect(subject.find_packages.map(&:id)).to eq(expected)
    end

    # TODO: check whether output is DLL or EXE or something else
    it 'should know its output dll' do
      should respond_to :output_dll
      expect(subject.output_dll('Release')).to eq(Paths.join 'bin', 'Release', 'Project.dll')
    end
  end
end

describe Albacore::Project, 'when given a PathnameWrap' do
  it 'should allow argument of PathnameWrap' do
    require 'albacore/paths'
    Albacore.create_project(Paths::PathnameWrap.new(File.expand_path('../testdata/Project/Project.fsproj', __FILE__)))
  end
end
describe Albacore::Project do

  it 'should read version from AssemblyInfo.cs' do
    p        = '../testdata/csharp/Exemplar/Exemplar/Exemplar.csproj'
    project  = Albacore.create_project(Paths::PathnameWrap.new(File.expand_path(p, __FILE__)))
    result   = project.default_assembly_version
    expected = '1.0.0.0'
    expect(expected).to eq(result)
  end
  it 'should read version from AssemblyInfo.cs in ModifiedAssemblyVersion' do
    p        = '../testdata/csharp/ModifiedAssemblyVersion/ModifiedAssemblyVersion/ModifiedAssemblyVersion.csproj'
    project  = Albacore.create_project(Paths::PathnameWrap.new(File.expand_path(p, __FILE__)))
    result   = project.default_assembly_version
    expected = '2.0.0.0'
    expect(expected).to eq(result)
  end
  it 'should return 1.0.0.0 when AssemblyVersion is not found' do
    p        = '../testdata/Project/Project.fsproj'
    project  = Albacore.create_project(Paths::PathnameWrap.new(File.expand_path(p, __FILE__)))
    result   = project.default_assembly_version
    expected = '1.0.0.0'
    expect(expected).to eq(result)
  end
  it 'properties_path should return project base path if assemblyinfo not found' do
    p        = '../testdata/Project/Project.fsproj'
    project  = Albacore.create_project(Paths::PathnameWrap.new(File.expand_path(p, __FILE__)))
    result   = project.assembly_info_path
    expected = File.dirname(project.path)
    expect(expected).to eq(result)

  end
  it 'properties path should return project base path if both are equivalent' do
    p        = '../testdata/Project/Project.fsproj'
    project  = Albacore.create_project(Paths::PathnameWrap.new(File.expand_path(p, __FILE__)))
    result   = project.assembly_info_path
    expected = File.dirname(project.path)
    expect(expected).to eq(result)
  end
end
