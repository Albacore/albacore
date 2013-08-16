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

describe Albacore::NugetModel::Package, "when doing some xml generation" do
  it "should be newable" do
    subject.should_not be_nil
  end
  [:metadata, :files, :to_xml, :to_xml_builder].each do |prop|
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

describe Albacore::NugetModel::Package, "from XML" do
  let :dir do
    File.basename(__FILE__)
  end
  let :xml do
    %{
<?xml version="1.0"?>
<package>
  <metadata>
    <id>Example</id>
    <version>1.2.3.4</version>
    <authors>Mr.Example</authors>
    <owners>Ms.Example</owners>
    <requireLicenseAcceptance>false</requireLicenseAcceptance>
    <description>Example package</description>
    <releaseNotes>Used for specs</releaseNotes>
    <copyright>none</copyright>
    <tags>example spec</tags>
    <dependencies>
      <dependency id="SampleDependency" version="1.0" />
    </dependencies>
  </metadata>
  <files>
    <file src="Full\\bin\\Debug\\*.dll" target="lib\\net40" /> 
    <file src="Full\\bin\\Debug\\*.pdb" target="lib\\net40" /> 
    <file src="Silverlight\\bin\\Debug\\*.dll" target="lib\\sl40" /> 
    <file src="Silverlight\\bin\\Debug\\*.pdb" target="lib\\sl40" /> 
    <file src="**\\*.cs" target="src" />
  </files>
</package>
}

  end
  let :parser do
    io = StringIO.new xml    
    Nokogiri::XML(io)
  end
  subject do
    package = Albacore::NugetModel::Package.from_xml xml
    puts "node: #{package.inspect}"
    puts "node meta: #{package.metadata.inspect}"
    package
  end
  it "should exist" do
    subject.should_not be_nil
  end
  it "should have the metadata properties of the XML above" do
    parser.
      xpath('.//metadata').
      children.
      reject { |n| n.name == 'dependencies' }.
      reject { |n| n.text? }.
      each do |node|
      name = Albacore::NugetModel::Metadata.underscore node.name
      subject.metadata.send(:"#{name}").should eq(node.inner_text.chomp)
    end
  end
  describe "all dependencies" do
    it "should have the SampleDependency dependency of the XML above" do
      parser.xpath('.//metadata/dependencies').children.reject{ |c| c.text? }.each do |dep|
        subject.metadata.dependencies.find{ |d| d.id == dep['id'] }.should_not be_nil
      end
    end 
  end
  it "should have all the files of the XML above" do
    subject.files.length.should eq(5)
  end
  it "should have a dep on SampleDependency version 1.0" do
    subject.metadata.dependencies.find { |d| d.id == 'SampleDependency' }.should_not be_nil
  end
end


describe "when reading xml from a fsproj file into Project/Metadata" do
  let :projfile do
    curr = File.dirname(__FILE__)
    File.join curr, "testdata", "Project.fsproj"
  end 
  subject do
    Albacore::NugetModel::Package.from_xxproj projfile
  end
  it "should find Name element" do
    subject.metadata.id.should eq 'Project'
  end
  it "should not find Version element" do
    subject.metadata.version.should eq ""
  end
  it "should find Authors element" do
    subject.metadata.authors.should eq "Henrik Feldt"
  end

  describe "when including files" do
    subject do
      Albacore::NugetModel::Package.from_xxproj projfile, :include_compile_files => true
    end
    it "should contain all files (just one)" do
      subject.files.length.should eq 1
    end
    it "should have a file of Library1.fs" do
      f = subject.files.first
      f.target.should eq('src/Library1.fs')
      f.src.should eq('Library1.fs')
    end
  end
end

describe "creating nuget from proj file" do
  let :projfile do
    curr = File.dirname(__FILE__)
    File.join curr, "testdata", "Project.fsproj"
  end 
  let :id do
    'Sample.Nuget'
  end
  let :curr do
    File.dirname(__FILE__)
  end
  let :expected_nuspec do
    File.join curr, "testdata", "#{id}.nuspec"
  end
  let :expected_nuspec_symbols do
    File.join curr, "testdata", "#{id}.symbols.nuspec"
  end
  let :config do
    cfg = Albacore::NugetsPack::Config.new
    cfg.target = 'net40'
    cfg.files  = [File.join(curr, 'testdata', '*.fsproj')]
    cfg.metadata do |m|
      m.id = id
      m.authors = 'haf'
      m.description = 'a nice lib'
      m.language = 'Danish'
      m.project_url = 'https://github.com/haf/Reasonable'
      m.license_url = 'https://github.com/haf/README.md'
      m.release_notes = %{
v10.0.0:
  - Some notes
}
      m.owners = 'haf'
      m.require_license_acceptance = false

      m.add_dependency 'Abc.Package', '>= 1.0.2'
      m.add_framework_dependency 'System.Transactions', '4.0.0'
    end
    cfg.gen_symbols # files: *.{pdb,dll,cs,fs,vb}
    cfg
  end

  subject do
    Albacore::NugetsPack::ProjectTask.new config.opts, [projfile]
  end 

  before do
    subject.execute
  end

  after do
    File.delete expected_nuspec if File.exists? expected_nuspec
    File.delete expected_nuspec_symbols if File.exists? expected_nuspec_symbols
  end

  it "should have generated a nuspec" do
    File.exists?(expected_nuspec).should be_true
  end

  it "should have generated a symbol nuspec" do
    File.exists?(expected_nuspec_symbols).should be_true
  end

  def contents xml, node
    xml.xpath(".//metadata/#{node}").inner_text
  end

  it "should have the specified metadata" do
    [expected_nuspect, expected_nuspec_symbols].each do |file|
      xml = 
      contents(xml, 'id').should eq(id)
      contents(xml, 'authors').should eq('haf')
      contents(xml, 'description').should eq('a nice lib')
      # ...
    end
  end

  describe "the symbol package" do
    it "should have the pdb files in the nuspec" do
      xml = Nokogiri::XML(File.open(expected_nuspec_symbols))
      %w[src\\Library1.fs lib\\net40\\Project.dll lib\\net40\\Project.pdb].each do |expected_target|
        xml.xpath('.//file').first { |f| f.target == expected_target }.should_not be_nil
      end
    end
  end

end

describe "creating nuget from dependent proj file" do
  it "should create dependencies for dependent projects"
  it "should create dependencies for dependent nugets"
end
