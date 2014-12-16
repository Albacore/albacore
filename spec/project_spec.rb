require 'spec_helper'
require 'albacore/semver'
require 'albacore/project'
require 'albacore/paths'

describe Albacore::Project, "when loading packages.config" do
  subject do
    p = File.expand_path('../testdata/Project/Project.fsproj', __FILE__)
    #puts "path: #{p}"
    Albacore::Project.new(p)
  end
  let :nlog do
    subject.declared_packages.find { |p| p.id == 'NLog' }
  end

  it 'should have a guid' do
    subject.guid.should match /^[A-F0-9]{8}(?:-[A-F0-9]{4}){3}-[A-F0-9]{12}$/i
  end

  it 'assumption: can gsub("[\{\}]", "")' do
    expect('{a}'.gsub(/[\{\}]/, '')).to eq 'a'
  end

  it 'should have an OutputPath' do
    subject.output_path('Debug').should_not be_nil
  end
  it 'should have the correct OutputPath' do
    subject.output_path('Debug').should eq('bin\\Debug\\')
  end
  it 'should also have a Release OutputPath' do
    subject.output_path('Release').should eq('bin\\Release\\')
    subject.try_output_path('Release').should eq('bin\\Release\\')
  end
  it 'should raise "ConfigurationNotFoundEror" if not found' do
    begin
      subject.output_path('wazaaa')
    rescue ::Albacore::ConfigurationNotFoundError
    end
  end
  it 'should return nil with #try_output_path(conf)' do
    subject.try_output_path('weeeo').should be_nil
  end
  it "should have three packages" do
    subject.declared_packages.length.should == 3
  end
  it "should contain NLog" do
    nlog.should_not be_nil
  end
  it "should have a four number on NLog" do
    nlog.version.should eq("2.0.0.2000")
  end
  it "should have a semver number" do
    nlog.semver.should eq(Albacore::SemVer.new(2, 0, 0))
  end
end

describe Albacore::Project, "when reading project file" do
  def project_path
    File.expand_path('../testdata/Project/Project.fsproj', __FILE__)
  end
  subject do
    Albacore::Project.new project_path
  end
  let :library1 do
    subject.included_files.find { |p| p.include == 'Library1.fs' }
  end
  it "should contain library1" do
    library1.should_not be_nil
  end

  describe 'public API' do
    it do
      subject.should respond_to(:name)
    end
    it do
      subject.should respond_to(:asmname)
    end
    it do
      subject.should respond_to(:version)
    end
    it do
      subject.should respond_to(:authors)
    end
    it 'should have five referenced assemblies' do
      subject.find_refs.length.should eq(5)
    end
    it 'knows about referenced packages' do
      subject.should respond_to(:declared_packages)
    end
    it 'knows about referenced projects' do
      subject.should respond_to(:declared_projects)
    end
    it 'should have three referenced packages' do
      expected = %w|Intelliplan.Util Newtonsoft.Json NLog|
      subject.find_packages.map(&:id).should eq(expected)
    end

    # TODO: check whether output is DLL or EXE or something else
    it 'should know its output dll' do
      should respond_to :output_dll
      subject.output_dll('Release').should eq(Paths.join 'bin', 'Release', 'Project.dll')
    end
  end
end

describe Albacore::Project, 'when given a PathnameWrap' do
  it 'should allow argument of PathnameWrap' do
    require 'albacore/paths'
    Albacore::Project.new(Paths::PathnameWrap.new(File.expand_path('../testdata/Project/Project.fsproj', __FILE__)))
  end
end
