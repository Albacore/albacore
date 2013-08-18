require 'spec_helper'
require 'support/sh_interceptor'
require 'albacore'
require 'albacore/task_types/nugets_pack'

shared_context "pack_config" do
  let :cfg do 
    cfg = Albacore::NugetsPack::Config.new
    cfg.out = 'src/packages'
    cfg.files = FileList['src/**/*.{csproj,fsproj}']
    cfg
  end
end

describe Albacore::NugetsPack::Cmd, "when calling #execute" do
  
  include_context 'pack_config'

  let :cmd do
    Albacore::NugetsPack::Cmd.new 'NuGet.exe', cfg.opts()
  end

  subject do 
    cmd.extend ShInterceptor
    cmd.execute './spec/testdata/example.nuspec', './spec/testdata/example.symbols.spec'
    cmd
  end

  describe "normal operation" do
    it "should run the correct executable" do
      subject.mono_command.should eq('NuGet.exe')
    end
    it "should include the correct parameters" do
      subject.mono_parameters.should eq(%w[Pack -OutputDirectory src/packages ./spec/testdata/example.nuspec])
    end
  end
  describe 'packing with -Symbols' do
    before do
      cfg.gen_symbols
    end
    it "should include -Symbols" do
      pending "waiting for a class that generates nuspecs and nothing else"
      subject.mono_parameters.should eq(%w[Pack -OutputDirectory src/packages -Symbols ./spec/testdata/example.nuspec])
    end
  end 
end

describe Albacore::NugetsPack::NuspecTask do
  include_context 'pack_config'

  it "accepts .nuspec files" do
    Albacore::NugetsPack::NuspecTask.accept?('some.nuspec').should be_true
  end

  let (:cmd) do
    Albacore::NugetsPack::Cmd.new 'NuGet.exe', cfg.opts()
  end

  subject do
    cmd
  end

  before do
    cmd.extend(ShInterceptor)
    task = Albacore::NugetsPack::NuspecTask.new cmd, cfg, './spec/testdata/example.nuspec'
    task.execute
  end

  it "should run the correct executable" do
    subject.mono_command.should eq('NuGet.exe')
  end
  it "should give the correct parameters" do
    pending "waiting for a class that generates the nuspec xml"
    subject.mono_parameters.should eq(%W[Pack -OutputDirectory src/packages ./spec/testdata/example.nuspec])
  end
end

describe Albacore::NugetsPack::ProjectTask do
  let :projfile do
    curr = File.dirname(__FILE__)
    File.join curr, "testdata", "Project.fsproj"
  end
  it "can be created" do
    Albacore::NugetsPack::ProjectTask.new((Map.new()), projfile)
  end
  it "rejects .nuspec files" do
    Albacore::NugetsPack::ProjectTask.accept?('some.nuspec').should eq false
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
    pending "finish Package#merge_with first"
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
