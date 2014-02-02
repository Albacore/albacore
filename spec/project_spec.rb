require 'spec_helper'
require 'albacore/semver'
require 'albacore/project'

describe Albacore::Project, "when loading packages.config" do
  subject do
    p = File.expand_path('../testdata/Project/Project.fsproj', __FILE__)
    #puts "path: #{p}"
    Albacore::Project.new(p)
  end
  let :nlog do
    subject.declared_packages.find { |p| p.id == 'NLog' }
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
  subject do
    p = File.expand_path('../testdata/Project/Project.fsproj', __FILE__)
    Albacore::Project.new(p)
  end
  let :library1 do
    subject.included_files.find { |p| p.include == 'Library1.fs' }
  end
  it "should contain library1" do
    library1.should_not be_nil
  end
end
