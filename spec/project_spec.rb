require_relative 'spec_helper'
require 'albacore/semver'
require 'albacore/project'
require 'albacore/paths'

describe Albacore::Project do
  subject do
    p = File.expand_path('../testdata/Project/Project.fsproj', __FILE__)
    #puts "path: #{p}"
    Albacore.create_project(p)
  end

  it 'has #guid' do
    expect(subject.guid).to match /^[A-F0-9]{8}(?:-[A-F0-9]{4}){3}-[A-F0-9]{12}$/i
  end

  it 'has xmldoc?' do
    expect(subject.xmldoc?).to be true
  end

  it 'assumption: can gsub("[\{\}]", "")' do
    expect('{a}'.gsub(/[\{\}]/, '')).to eq 'a'
  end

  describe "#outputs" do
    let :outputs do
      subject.outputs 'Debug', 'net45'
    end

    it 'non-empty array' do
      expect(outputs).to_not be_empty
    end

    it 'a DLL' do
      expect(outputs).to include(
        Albacore::OutputArtifact.new 'bin/Debug/Project.dll', Albacore::OutputArtifact::LIBRARY
      )
    end

    it 'should raise "ConfigurationNotFoundEror" if not found' do
      begin
        subject.outputs('UNKNOWN_Configuration', 'net451')
      rescue ::Albacore::ConfigurationNotFoundError
      end
    end
  end

  describe "#declared_packages" do
    it "has three" do
      expect(subject.declared_packages.length).to eq 3
    end

    let :nlog do
      subject.declared_packages.find { |p| p.id == 'NLog' }
    end

    it "contains NLog" do
      expect(nlog).to_not be_nil
    end

    it "should have a four number on NLog" do
      expect(nlog.version).to eq("2.0.0.2000")
    end

    it "should have a semver number" do
      expect(nlog.semver).to eq(Albacore::SemVer.new(2, 0, 0))
    end
  end
end

describe Albacore::Project, "reading project file" do
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
    expect(subject.target_framework).to eq "net451"
    expect(subject.target_frameworks).to eq %w|net451|
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
  end
end

describe Albacore::Project, "for netcore" do
  def project_path
    File.expand_path('../testdata/console-core-argu/ConsoleArgu.fsproj', __FILE__)
  end

  subject do
    Albacore.create_project project_path
  end

  it "#id" do
    expect(subject.id).to eq 'ConsoleArgu'
  end

  it "#name" do
    expect(subject.name).to eq 'ConsoleArgu'
  end

  it "#asmname" do
    expect(subject.asmname).to eq 'ConsoleArgu'
  end

  it "#proj_filename_noext" do
    expect(subject.proj_filename_noext).to eq 'ConsoleArgu'
  end

  it '#netcore?' do
    expect(subject.netcore?).to eq true
  end

  it '#target_frameworks' do
    expect(subject.target_frameworks).to eq %w|netstandard2.0 net461|
  end

  it '#outputs' do
    expected = [
      Albacore::OutputArtifact.new(
        'bin/Release/netstandard2.0/ConsoleArgu.dll',
        Albacore::OutputArtifact::LIBRARY),

      Albacore::OutputArtifact.new(
        'bin/Release/netstandard2.0/ConsoleArgu.xml',
        Albacore::OutputArtifact::XMLDOC)
    ]
    expect(subject.outputs('Release', 'netstandard2.0')).to eq expected
  end

  it '#paket_packages' do
    dps = subject.declared_packages.group_by { |d| d.id }
    expect(dps).to_not be_empty

    h = Hash[dps]
    expect(h).to_not be_empty
    expect(h['FSharp.Core'].length).to eq(2)
    expect(h['Argu'].length).to eq(2)
  end
end

describe Albacore::Project, 'with PathnameWrap' do
  it 'should allow argument of PathnameWrap' do
    require 'albacore/paths'
    Albacore.create_project(Paths::PathnameWrap.new(File.expand_path('../testdata/Project/Project.fsproj', __FILE__)))
  end
end

describe Albacore::Project, "with AssemblyInfo.cs" do
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
