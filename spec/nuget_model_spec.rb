require 'spec_helper'
require 'albacore/nuget_model'

describe Albacore::NugetModel::Metadata do
  [:id, :version, :authors, :description, :language, :project_url, :license_url, :release_notes, :dependencies, :framework_assemblies].each do |prop|
    it "responds to :#{prop}" do
      subject.should respond_to(prop)
    end
  end
  describe "when adding a dependency" do
    before do 
      subject.add_dependency 'DepId', '=> 3.4.5'
    end
    let :dep do
      subject.dependencies.first
    end
    it "should contain the dependency version" do
      dep.version.should eq('=> 3.4.5')
    end
    it "should contain the dependency id" do
      dep.id.should eq('DepId')
    end
    it "should contain only one dependency" do
      subject.dependencies.length.should eq(1)
    end
  end
  describe "when adding a framework dependency" do
    before do
      subject.add_framework_dependency 'System.Transactions', '2.0.0' 
    end
    let :dep do
      subject.framework_assemblies.first
    end
    it "should contain the dependency id" do
      dep.id.should eq('System.Transactions')
    end
    it "should contain the dependency version" do
      dep.version.should eq('2.0.0')
    end
    it "should contain a single dependency" do
      subject.framework_assemblies.length.should eq(1)
    end
  end
end

describe Albacore::NugetModel::PackageWriter, "when doing some xml generation" do
  it "should be newable" do
    subject.should_not be_nil
  end
  [:metadata, :files].each do |prop|
    it "should respond to #{prop}" do
      subject.should respond_to(prop)
    end
  end
  it "should generate default metadata" do
    subject.to_xml.should include('<metadata')
  end
  it "should generate default files" do
    subject.to_xml.should include('<files')
  end
end


