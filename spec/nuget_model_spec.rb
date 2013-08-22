require 'spec_helper'
require 'albacore/paths'
require 'albacore/nuget_model'

describe Albacore::NugetModel::Metadata do
  [:id, :version, :authors, :description, :language, :project_url, :license_url, :release_notes, :owners, :require_license_acceptance, :copyright, :tags, :dependencies, :framework_assemblies].each do |prop|
    it "responds to :#{prop}" do
      subject.should respond_to(prop)
    end
  end

  describe "when adding a dependency" do
    before do 
      subject.add_dependency 'DepId', '=> 3.4.5'
    end
    let :dep do
      subject.dependencies['DepId']
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
      subject.framework_assemblies.first[1]
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
    <<XML
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd">
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
      <dependency id="SampleDependency" version="1.0"/>
    </dependencies>
  </metadata>
  <files>
    <file src="Full/bin/Debug/*.dll" target="lib/net40"/>
    <file src="Full/bin/Debug/*.pdb" target="lib/net40"/>
    <file src="Silverlight/bin/Debug/*.dll" target="lib/sl40"/> 
    <file src="Silverlight/bin/Debug/*.pdb" target="lib/sl40"/> 
    <file src="**/*.cs" target="src"/>
  </files>
</package>
XML
  end

  let :parser do
    io = StringIO.new xml    
    Nokogiri::XML(io)
  end
  let :ns do
    { ng: 'http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd' }
  end
  subject do
    puts "parser: #{parser}"
    package = Albacore::NugetModel::Package.from_xml xml
    #puts "node: #{package.inspect}"
    #puts "node meta: #{package.metadata.inspect}"
    package
  end
  it "should exist" do
    subject.should_not be_nil
  end
  it "should have the metadata properties of the XML above" do
    parser.
      xpath('./ng:metadata', ns).
      children.
      reject { |n| n.name == 'dependencies' }.
      reject { |n| n.text? }.
      each do |node|
      name = Albacore::NugetModel::Metadata.underscore node.name
      subject.metadata.send(:"#{name}").should eq(node.inner_text.chomp)
    end
  end

  # on Windows this fails due to replacement of path separators (by design)
  unless ::Rake::Win32.windows?
    it "should generate the same (semantic) XML as above" do
      Nokogiri::XML(subject.to_xml, &:noblanks).to_xml.should eq(Nokogiri::XML(StringIO.new(xml), &:noblanks).to_xml)
    end
  end

  describe "all dependencies" do
    it "should have the SampleDependency dependency of the XML above" do
      parser.xpath('./ng:metadata/ng:dependencies', ns).children.reject{ |c| c.text? }.each do |dep|
        subject.metadata.dependencies[dep['id']].should_not be_nil
      end
    end 
  end

  it "should have all the files of the XML above" do
    subject.files.length.should eq(5)
  end

  it "should have a dep on SampleDependency version 1.0" do
    subject.metadata.dependencies['SampleDependency'].should_not be_nil
  end
end


shared_context 'metadata_dsl' do
  let :m do
    subject.metadata
  end

  def self.has_value sym, e
    it "should have overridden #{sym}, to be #{e}" do
      m.send(sym).should eq e
    end
  end

  def self.has_dep name, version
    it "has dependency on '#{name}'" do
      m.dependencies.has_key?(name).should be_true
    end
    it "overrode dependency on '#{name}'" do
      m.dependencies[name].version.should eq version
    end
  end

  def self.has_not_dep name
    it "does not have a dependency on #{name}" do
      m.dependencies.has_key?(name).should be_false
    end
  end

  def self.has_file src, target, exclude = nil
    src, target = norm(src), norm(target)
    it "has file[#{src}] (should not be nil)" do
      file = subject.files.find { |f| f.src == src }
     #  puts "## ALL FILES ##"
     #  subject.files.each do |f|
     #    puts "subject.files: #{subject.files}, index of: #{subject.files.find_index { |f| f.src == src }}"
     #    puts "#{f.inspect}"
     #  end
      file.should_not be_nil 
    end

    it "has file[#{src}].target == '#{target}'" do
      file = subject.files.find { |f| f.src == src }
      file.target.should eq target
    end 
  end

  def self.has_not_file src
    src = norm src
    it "has not file[#{src}]" do
      file = subject.files.find { |f| f.src == src }
      file.should be_nil
    end
  end

  def self.norm str
    Albacore::Paths.normalise_slashes str
  end  
end

describe "when reading xml from a fsproj file into Project/Metadata" do
  let :projfile do
    curr = File.dirname(__FILE__)
    File.join curr, "testdata", "Project", "Project.fsproj"
  end 
  subject do
    Albacore::NugetModel::Package.from_xxproj_file projfile
  end

  include_context 'metadata_dsl'

  it "should find Name element" do
    m.id.should eq 'Project'
  end

  it "should not find Version element" do
    m.version.should eq nil
  end

  it "should find Authors element" do
    m.authors.should eq "Henrik Feldt"
  end

  describe "when including files" do
    subject do
      Albacore::NugetModel::Package.from_xxproj_file projfile, :symbols => true
    end
    it "should contain all files (just one) and all dll and pdb files (two)" do
      subject.files.length.should eq 3
    end

    has_file 'Library1.fs', 'src/Library1.fs'
    has_file 'bin/Debug/Project.dll', 'lib/net40'
    has_file 'bin/Debug/Project.pdb', 'lib/net40'
  end
end


describe Albacore::NugetModel::Package, "overriding metadata" do
  let :p1 do
    p = Albacore::NugetModel::Package.new.with_metadata do |m|
      m.id = 'A.B'
      m.version = '2.1.3'
      m.add_dependency 'NLog', '2.0'
    end
    p.add_file 'CodeFolder/A.cs', 'lib/CodeFolder/A.cs'
    p.add_file 'CodeFolder/*.fs', 'lib', 'AssemblyInfo.fs'
  end 
  let :p2 do
    Albacore::NugetModel::Package.new.with_metadata do |m|
      m.id = 'A.B.C'
      m.add_dependency 'NLog', '2.3'
      m.add_dependency 'Castle.Core', '3.0.0'
      m.owners = 'Henrik Feldt'
    end
  end
  subject do
    p1.merge_with p2
  end

  include_context 'metadata_dsl'

  describe "when overriding:" do
    has_value :id, 'A.B.C'
    has_value :owners, 'Henrik Feldt'
    has_value :version, '2.1.3'

    has_dep 'NLog', '2.3'
    has_dep 'Castle.Core', '3.0.0'

    has_file 'CodeFolder/A.cs', 'lib/CodeFolder/A.cs'
    has_file 'CodeFolder/*.fs', 'lib', 'AssemblyInfo.fs'
  end
end

describe "creating nuget (not symbols) from dependent proj file" do

  let :projfile do
    curr = File.dirname(__FILE__)
    File.join curr, "testdata", "TestingDependencies", "Sample.Commands", "Sample.Commands.fsproj"
  end 

  subject do
    Albacore::NugetModel::Package.from_xxproj_file projfile,
      :known_projects => %w[Sample.Core],
      :version        => '2.3.0',
      :configuration  => 'Debug'
  end
  
  include_context 'metadata_dsl'

  # from fsproj
  has_dep 'Sample.Core', '2.3.0'

  # from packages.config
  has_dep 'Magnum', '2.1.0'
  has_dep 'MassTransit', '2.8.0'
  has_dep 'Newtonsoft.Json', '5.0.6'

  # actual nuspec contents
  has_file 'bin/Debug/Sample.Commands.dll', 'lib/net40'
  has_file 'bin/Debug/Sample.Commands.xml', 'lib/net40'
end

describe "creating nuget on dependent proj file" do

  let :projfile do
    curr = File.dirname(__FILE__)
    File.join curr, "testdata", "TestingDependencies", "Sample.Commands", "Sample.Commands.fsproj"
  end 

  let :opts do
    { project_dependencies: false,
      known_projects:       %w[Sample.Core],
      version:             '2.3.0' }
  end

  subject do
    Albacore::NugetModel::Package.from_xxproj_file projfile, opts
  end
  
  include_context 'metadata_dsl'

  describe 'without project_dependencies' do
    # just as the opts in the main describe says...
    has_not_dep 'Sample.Core'
    has_dep 'Magnum', '2.1.0'
    has_dep 'MassTransit', '2.8.0'
    has_dep 'Newtonsoft.Json', '5.0.6'
    has_file 'bin/Debug/Sample.Commands.dll', 'lib/net40'
    has_file 'bin/Debug/Sample.Commands.xml', 'lib/net40'
    has_not_file 'Library.fs'
  end

  describe 'without nuget_dependencies' do
    let :opts do
      { nuget_dependencies: false,
        known_projects:     %w[Sample.Core],
        version:           '2.3.0' }
    end

    has_dep 'Sample.Core', '2.3.0'
    has_not_dep 'Magnum'
    has_not_dep 'MassTransit'
    has_not_dep 'Newtonsoft.Json'
    has_file 'bin/Debug/Sample.Commands.dll', 'lib/net40'
    has_file 'bin/Debug/Sample.Commands.xml', 'lib/net40'
    has_not_file 'Library.fs'
  end

  describe 'without symbols' do
    let :opts do
      { symbols:        false,
        known_projects: %w[Sample.Core],
        version:       '2.3.0' }
    end
    has_dep 'Sample.Core', '2.3.0'
    has_dep 'Magnum', '2.1.0'
    has_dep 'MassTransit', '2.8.0'
    has_dep 'Newtonsoft.Json', '5.0.6'
    has_file 'bin/Debug/Sample.Commands.dll', 'lib/net40'
    has_file 'bin/Debug/Sample.Commands.xml', 'lib/net40'
    has_not_file 'Library.fs'
  end

  describe 'with symbols' do
    let :opts do
      { symbols:        true,
        known_projects: %w[Sample.Core],
        version:        '2.3.0' }
    end
    has_dep 'Sample.Core', '2.3.0'
    has_dep 'Magnum', '2.1.0'
    has_dep 'MassTransit', '2.8.0'
    has_dep 'Newtonsoft.Json', '5.0.6'
    has_not_file 'bin/Debug/Sample.Commands.xml'
    has_file 'bin/Debug/Sample.Commands.dll', 'lib/net40'
    has_file 'bin/Debug/Sample.Commands.pdb', 'lib/net40'
    has_file 'Library.fs', 'src/Library.fs'
  end

  describe 'Release-only output' do
    let :projfile do
      curr = File.dirname(__FILE__)
      File.join curr, "testdata", "EmptyProject", "EmptyProject.csproj"
    end 
    has_not_file 'bin/Debug/Sample.Commands.dll'
    has_not_file 'bin/Debug/EmptyProject.dll' 
    has_not_file 'bin/Debug/EmptyProject.xml' 
    has_file 'bin/Release/EmptyProject.dll', 'lib/net40'
  end
end
