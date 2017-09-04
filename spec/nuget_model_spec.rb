require 'spec_helper'
require 'shared_contexts'
require 'albacore/paths'
require 'albacore/nuget_model'
require 'albacore/application'

##  Table of contents
#
# - Structure of Metadata
# - Package#to_xml
# - Package#from_xml
# - Package#from_xxproj_file (full fw)
# - Package#from_xxproj_file with metadata/title in proj file (full fw)
# - Package#with_metadata
# - Package#from_xxproj_file with packages.config (full fw)
# - Package#from_xxproj_file with dependent project (full fw)
#

describe Albacore::NugetModel::Metadata do
  [ :id, :version, :authors, :title, :description, :summary, :language,
    :project_url, :license_url, :release_notes, :owners,
    :require_license_acceptance, :copyright, :tags, :dependencies,
    :framework_assemblies ].each do |prop|
    it "responds to :#{prop}" do
      expect(subject).to respond_to(prop)
    end
  end

  describe "adding dependency w/o group" do
    before do 
      subject.add_dependency 'DepId', '[3.4.5, 4.0)', '', false
    end

    let :dep do
      subject.dependencies['DepId']
    end

    it "contains the dependency version" do
      expect(dep.version).to eq '[3.4.5, 4.0)'
    end

    it "contains the dependency id" do
      expect(dep.id).to eq 'DepId'
    end

    it "has group=false from invocation" do
      expect(dep.group).to eq false
    end

    it "defaults to target_framework=''" do
      expect(dep.target_framework).to be_empty
    end

    it "contains only one dependency" do
      expect(subject.dependencies.length).to eq 1
    end

    describe "#to_xml" do
      let :xml do
        subject.to_xml
      end

      it "generates a list" do
        expect(xml).to include("  <dependencies>\n    <dependency id=\"DepId\" version=\"[3.4.5, 4.0)\"/>")
      end
    end
  end

  describe "adding framework dependency" do
    before do
      subject.add_framework_dependency 'System.Transactions', '2.0.0' 
    end

    let :dep do
      subject.framework_assemblies.first[1]
    end

    it "should contain the dependency id" do
      expect(dep.id).to eq('System.Transactions')
    end

    it "should contain the dependency version" do
      expect(dep.version).to eq('2.0.0')
    end

    it "should contain a single dependency" do
      expect(subject.framework_assemblies.length).to eq(1)
    end
  end

  describe "when adding dependency w/ groups" do
    before do
      subject.add_dependency 'Dep', '[1.2.3, 2.0)', 'net461'
      subject.add_dependency 'Dep', '[1.2.3, 2.0)', 'netstandard2.0'
    end

    it "has both deps" do
      expect(subject.dependencies.length).to eq 2
    end

    it "rejects non-grouped dependencies (after grouped)" do
      expect(lambda {
        subject.add_dependency 'Hepp', '1.2.3', '', false
      }).to raise_error(ArgumentError)
    end

    describe "#to_xml" do
      let :xml do
        subject.to_xml
      end

      it "generates a list" do
        expected = <<XML
  <dependencies>
    <group targetFramework="net461">
      <dependency id="DepId" version="[3.4.5, 4.0)" />
    </group>
    <group targetFramework="netstandard2.0">
      <dependency id="DepId" version="[3.4.5, 4.0)" />
    </group>
  </dependencies>
XML
        expect(Nokogiri::XML(xml, &:noblanks).to_xml).to \
          include(Nokogiri::XML(StringIO.new(xml), &:noblanks).to_xml)
      end
    end
  end

  describe "inverse rejection (no group, then group)" do
    before do
      subject.add_dependency 'Dep', '[1.2.3, 2.0)', '', false
    end

    it "rejects grouped dependencies (after non-grouped)" do
      expect(lambda {
        subject.add_dependency 'Hepp', '1.2.3', '', true
      }).to raise_error(ArgumentError)
    end
  end
end

describe Albacore::NugetModel::Package, "#to_xml" do
  it "should be newable" do
    expect(subject).to_not be_nil
  end

  [:metadata, :files, :to_xml, :to_xml_builder].each do |prop|
    it "should respond to #{prop}" do
      expect(subject).to respond_to(prop)
    end
  end

  it "should generate default metadata" do
    expect(subject.to_xml).to include('<metadata')
  end

  it "should not generate default files" do
    expect(subject.to_xml).to_not include('<files')
  end
end

describe Albacore::NugetModel::Package, "#from_xml" do
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
    <summary>Example package summary</summary>
    <releaseNotes>Used for specs</releaseNotes>
    <copyright>none</copyright>
    <tags>example spec</tags>
    <dependencies>
      <group>
        <dependency id="FSharp.Core" version="[4.1, 4.2)"/>
      </group>
      <group targetFramework="netstandard1.6">
        <dependency id="System.Net" version="[1.1, 2.0)"/>
      </group>
    </dependencies>
  </metadata>
  <files>
    <file src="Full/bin/Debug/*.dll" target="lib/net45"/>
    <file src="Full/bin/Debug/*.pdb" target="lib/net45"/>
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
    package = Albacore::NugetModel::Package.from_xml xml
    package
  end

  it "exists" do
    expect(subject).to_not be_nil
  end

  it "has identical metadata props" do
    parser.
      xpath('./ng:metadata', ns).
      children.
      reject { |n| n.name == 'dependencies' }.
      reject { |n| n.text? }.
      each do |node|
      name = Albacore::NugetModel::Metadata.underscore node.name
      expect(subject.metadata.send(:"#{name}")).to eq(node.inner_text.chomp)
    end
  end

  # on Windows this fails due to replacement of path separators (by design)
  unless ::Albacore.windows?
    it 'roundtrips XML' do
      expect(Nokogiri::XML(subject.to_xml, &:noblanks).to_xml).to \
        eq(Nokogiri::XML(StringIO.new(xml), &:noblanks).to_xml)
    end
  end

  describe "all dependencies" do
    it "should have the SampleDependency dependency of the XML above" do
      parser.xpath('./ng:metadata/ng:dependencies', ns).children.reject{ |c| c.text? }.each do |dep|
        expect(subject.metadata.dependencies[dep['id']]).to_not be_nil
      end
    end 
  end

  it "should have all the files of the XML above" do
    expect(subject.files.length).to eq(5)
  end

  it "should have a dep on SampleDependency version 1.0" do
    expect(subject.metadata.dependencies['FSharp.Core']).to_not be_nil
  end
end

describe Albacore::NugetModel::Package, "#from_xxproj_file (full) => Package" do
  let :projfile do
    curr = File.dirname(__FILE__)
    File.join curr, "testdata", "Project", "Project.fsproj"
  end

  subject do
    Albacore::NugetModel::Package.from_xxproj_file projfile
  end

  include_context 'package_metadata_dsl'

  it "should find Name element" do
    expect(m.id).to eq 'Project'
  end

  it "should not find Version element" do
    expect(m.version).to eq nil
  end

  it "should find Authors element" do
    expect(m.authors).to eq "Henrik Feldt"
  end

  it 'should have the same title as <Name />' do
    expect(m.title).to eq 'Project'
  end

  describe "when including files" do
    subject do
      Albacore::NugetModel::Package.from_xxproj_file projfile, :symbols => true
    end
    it "should contain all files (just one) and all dll and pdb+mdb files (two)" do
      expect(subject.files.length).to eq 4
    end

    has_file 'Library1.fs', 'src/Library1.fs'
    has_file 'bin/Debug/Project.dll', 'lib/net45'
    has_file 'bin/Debug/Project.pdb', 'lib/net45'
    has_file 'bin/Debug/Project.dll.mdb', 'lib/net45'
  end
end

describe Albacore::NugetModel::Package, "#from_xxproj_file (core) => Package" do
  let :projfile do
    curr = File.dirname(__FILE__)
    File.join curr, "testdata", "console-core-argu", "ConsoleArgu.fsproj"
  end

  subject do
    Albacore::NugetModel::Package.from_xxproj_file projfile
  end

  include_context 'package_metadata_dsl'

  it "targets netstandard2.0 and net461" do
    expect(subject.target_frameworks).to eq %w|netstandard2.0 net461|
  end
end

describe Albacore::NugetModel::Package, "#from_xxproj_file (full) => Package w/ title" do
  let :projfile do
    curr = File.dirname(__FILE__)
    File.join curr, "testdata", "Project", "ProjectWithTitle.fsproj"
  end 

  subject do
    Albacore::NugetModel::Package.from_xxproj_file projfile
  end

  include_context 'package_metadata_dsl'

  it "should find Name element" do
    expect(m.id).to eq 'Project'
  end

  it "should not find Version element" do
    expect(m.version).to be_nil
  end

  it "should find Authors element" do
    expect(m.authors).to eq "Henrik Feldt"
  end

  it 'should use the Name tag here, too' do
    expect(m.title).to eq 'Project for Glorious Success'
  end
end

describe Albacore::NugetModel::Package, "#with_metadata (full)" do
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
    p = Albacore::NugetModel::Package.new.with_metadata do |m|
      m.id = 'A.B.C'
      m.add_dependency 'NLog', '2.3'
      m.add_dependency 'Castle.Core', '3.0.0'
      m.owners = 'Henrik Feldt'
    end
    p.add_file 'CodeFolder/p2.fs', 'lib/CodeFolder/p2.fs'
  end
  subject do
    p1.merge_with p2
  end

  include_context 'package_metadata_dsl'

  describe "when overriding:" do
    has_value :id, 'A.B.C'
    has_value :owners, 'Henrik Feldt'
    has_value :version, '2.1.3'

    has_dep 'NLog', '2.3'
    has_dep 'Castle.Core', '3.0.0'

    has_file 'CodeFolder/A.cs', 'lib/CodeFolder/A.cs'
    has_file 'CodeFolder/p2.fs', 'lib/CodeFolder/p2.fs'
    has_file 'CodeFolder/*.fs', 'lib', 'AssemblyInfo.fs'
  end
end

describe Albacore::NugetModel::Package, "(full) w/ packages.config" do

  let :projfile do
    curr = File.dirname(__FILE__)
    File.join curr, "testdata", "TestingDependencies", "Sample.Commands", "Sample.Commands.fsproj"
  end 

  subject do
    Albacore::NugetModel::Package.from_xxproj_file projfile,
      :known_projects => %w[Sample.Core],
      :version        => '2.3.0', # TODO: [2.3.0, 3.0.0)
      :configuration  => 'Debug'
  end

  include_context 'package_metadata_dsl'

  # from fsproj
  has_dep 'Sample.Core', '2.3.0' # TODO: [2.3.0, 3.0.0)

  # from packages.config
  has_dep 'Magnum', '2.1.0' # TODO: [2.3.0, 3.0.0)
  has_dep 'MassTransit', '2.8.0' # TODO: [2.3.0, 3.0.0)
  has_dep 'Newtonsoft.Json', '5.0.6' # TODO: [2.3.0, 3.0.0)

  # actual nuspec contents
  has_file 'bin/Debug/Sample.Commands.dll', 'lib/net45' # TODO: [2.3.0, 3.0.0)
  has_file 'bin/Debug/Sample.Commands.xml', 'lib/net45' # TODO: [2.3.0, 3.0.0)

  describe 'when dotnet_version is set' do
    subject do
      Albacore::NugetModel::Package.from_xxproj_file projfile,
        known_projects: %w[Sample.Core],
        dotnet_version: 'mono32'
    end
    # actual nuspec contents
    has_file 'bin/Debug/Sample.Commands.dll', 'lib/mono32'
    has_file 'bin/Debug/Sample.Commands.xml', 'lib/mono32'
  end
end

describe Albacore::NugetModel::Package, "(full) w/ dependent project" do
  let :projfile do
    curr = File.dirname(__FILE__)
    File.join curr, "testdata", "TestingDependencies", "Sample.Commands",
              "Sample.Commands.fsproj"
  end 

  let :opts do
    { project_dependencies: false,
      known_projects:       %w[Sample.Core],
      version:             '2.3.0' }
  end

  subject do
    Albacore::NugetModel::Package.from_xxproj_file projfile, opts
  end

  include_context 'package_metadata_dsl'

  describe 'without project_dependencies' do
    # just as the opts in the main describe says
    has_not_dep 'Sample.Core'
    has_dep 'Magnum', '2.1.0'
    has_dep 'MassTransit', '2.8.0'
    has_dep 'Newtonsoft.Json', '5.0.6'
    has_file 'bin/Debug/Sample.Commands.dll', 'lib/net45'
    has_file 'bin/Debug/Sample.Commands.xml', 'lib/net45'
    has_not_file 'Library.fs'
  end

  describe 'with project_dependencies' do

    let :opts do
      { project_dependencies: true,
        known_projects:       %w[Sample.Core],
        version:             '2.3.0' }
    end

    # just as the opts in the main describe says
    has_dep 'Sample.Core', '2.3.0'
    has_dep 'Magnum', '2.1.0'
    has_dep 'MassTransit', '2.8.0'
    has_dep 'Newtonsoft.Json', '5.0.6'
    has_file 'bin/Debug/Sample.Commands.dll', 'lib/net45'
    has_file 'bin/Debug/Sample.Commands.xml', 'lib/net45'
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
    has_file 'bin/Debug/Sample.Commands.dll', 'lib/net45'
    has_file 'bin/Debug/Sample.Commands.xml', 'lib/net45'
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
    has_file 'bin/Debug/Sample.Commands.dll', 'lib/net45'
    has_file 'bin/Debug/Sample.Commands.xml', 'lib/net45'
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
    has_file 'bin/Debug/Sample.Commands.dll', 'lib/net45'
    has_file 'bin/Debug/Sample.Commands.pdb', 'lib/net45'
    has_file 'Library.fs', 'src/Library.fs'
  end

  describe 'Release-only output' do
    # In this case we only have a Release output, and the nuget should pick the
    # single one that exists.
    # The idea is that we should succeed rather than fail, to remove friction, but
    # there should also be a warning about it in the output; that an OutputPath
    # was selected from a specific configuration that wasn't configured in the
    # task type.
    let :projfile do
      curr = File.dirname(__FILE__)
      File.join curr, "testdata", "EmptyProject", "EmptyProject.csproj"
    end 
    has_not_file 'bin/Debug/Sample.Commands.dll'
    has_not_file 'bin/Debug/EmptyProject.dll' 
    has_not_file 'bin/Debug/EmptyProject.xml' 
    has_file 'bin/Release/EmptyProject.dll', 'lib/net45'
  end
end