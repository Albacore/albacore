# encoding: utf-8

require 'spec_helper'
require 'shared_contexts'
require 'support/sh_interceptor'
require 'albacore'
require 'albacore/task_types/nugets_pack'
require 'albacore/nuget_model'

include ::Albacore::NugetsPack

class ConfigFac
  def self.create id, curr, gen_symbols = true
    cfg = Albacore::NugetsPack::Config.new
    cfg.target        = 'mono32'
    cfg.configuration = 'Debug'
    cfg.files         = Dir.glob(File.join(curr, 'testdata', 'Project', '*.fsproj'))
    cfg.out           = 'spec/testdata/pkg'
    cfg.exe           = 'NuGet.exe'
    cfg.with_metadata do |m|
      m.id            = id
      m.authors       = 'haf'
      m.owners        = 'haf owner'
      m.description   = 'a nice lib'
      m.language      = 'Danish'
      m.project_url   = 'https://github.com/haf/Reasonable'
      m.license_url   = 'https://github.com/haf/README.md'
      m.version       = '0.2.3'
      m.release_notes = %{
v10.0.0:
  - Some notes
}
      m.require_license_acceptance = false

      m.add_dependency 'Abc.Package', '>= 1.0.2'
      m.add_framework_dependency 'System.Transactions', '4.0.0'
    end
    cfg.gen_symbols if gen_symbols # files: *.{pdb,dll,all compiled files}
    cfg
  end
end

shared_context 'pack_config' do
  let :id do
    'Sample.Nuget'
  end
  let :curr do
    File.dirname(__FILE__)
  end
  let :config do
    cfg = ConfigFac.create id, curr, true
  end
end

shared_context 'pack_config no symbols' do
  let :id do
    'Sample.Nuget'
  end
  let :curr do
    File.dirname(__FILE__)
  end
  let :config do
    cfg = ConfigFac.create id, curr, false
  end
end

describe Albacore::NugetsPack::Config, 'when setting #nuget_gem_exe' do
  it 'should be set to path that exists' do
    subject.nuget_gem_exe
    expect(subject.exe).to be_a String
    expect(File.exists?( subject.exe)).to be true
  end
end
# testing the command for nuget

describe Cmd, "when calling #execute" do
  
  include_context 'path testing'

  let :cmd do
    Cmd.new 'NuGet.exe', config.opts()
  end

  subject do 
    cmd.extend ShInterceptor
    cmd.execute './spec/testdata/example.nuspec', './spec/testdata/example.symbols.nuspec'
    #puts "## INVOCATIONS:"
    #cmd.invocations.each do |i|
    #  puts "#{i}"
    #end
    cmd
  end

  describe "first invocation" do
    include_context 'pack_config'
    it "should run the correct executable" do
      expect(subject.mono_command(0)).to eq('NuGet.exe')
    end
    it "should include the correct parameters" do
      expect(subject.mono_parameters(0)).to eq(%W[Pack -OutputDirectory #{path 'spec/testdata/pkg'} ./spec/testdata/example.nuspec])
    end
  end

  describe "second invocation" do
    include_context 'pack_config'
    it "should include -Symbols" do
      expect(subject.mono_parameters(1)).to eq(%W[Pack -OutputDirectory #{path 'spec/testdata/pkg'} -Symbols ./spec/testdata/example.symbols.nuspec])
    end
  end

  describe "without symbols" do
    include_context 'pack_config no symbols'
    subject do
      cmd.extend ShInterceptor
      cmd.execute './spec/testdata/example.nuspec'
      cmd
    end
    it 'should not include -Symbols'  do
      expect(subject.mono_parameters(0)).to eq(%W[Pack -OutputDirectory #{path 'spec/testdata/pkg'} ./spec/testdata/example.nuspec])
    end
    it 'should not have a second invocation' do
      expect(subject.invocations.length).to eq(1)
    end
  end
end

describe Cmd, 'when calling :get_nuget_path_of' do
  include_context 'pack_config'

  subject do
    Cmd.new 'NuGet.exe', config.opts()
  end

  let :sample1 do
<<EXAMPLE_OUTPUT
Attempting to build package from 'MyNuget.Package.nuspec'.
Successfully created package 'Y:\\Shared\\build\\pkg\\MyNuget.Package.1.0.0.nupkg'.
Successfully created package 'Y:\\Shared\\build\\pkg\\MyNuget.Package.1.0.0.symbols.nupkg'.
EXAMPLE_OUTPUT
  end

  let :sample2 do
<<EXAMPLE_OUTPUT
Attempting to build package from 'MyNuget.Package.nuspec'.
Successfully created package '/home/xyz/Shared/build/pkg/MyNuget.Package.1.0.0.nupkg'.
Successfully created package '/home/xyz/Shared/build/pkg/MyNuget.Package.1.0.0.symbols.nupkg'.
EXAMPLE_OUTPUT
  end

  let :sample3 do
<<EXAMPLE_OUTPUT
Attempting to build package from 'MyNuget.Package.nuspec'.
Successfully created package '/home/xyz/Shared/build/pkg/MyNuget.Package.1.0.0-alpha3.nupkg'.
Successfully created package '/home/xyz/Shared/build/pkg/MyNuget.Package.1.0.0-alpha3.symbols.nupkg'.
EXAMPLE_OUTPUT
  end

  let :sample4 do
<<EXAMPLE_OUTPUT
Attempting to build package from 'MyNuget.Package.nuspec'.
Successfully created package '/home/xyz/Shared/build/pkg/MyNuget.Package.1.0.0-alpha.nupkg'.
EXAMPLE_OUTPUT
  end

  let :sample5 do
<<EXAMPLE_OUTPUT
Attempting to build package from 'Fröken.nuspec'.
Successfully created package '/home/xyz/Shared/build/pkg/Fröken.1.0.0-alpha.nupkg'.
EXAMPLE_OUTPUT
  end

  it "should match sample1 with last nupkg mentioned" do
    match = subject.send(:get_nuget_path_of) { sample1 }
    expect(match).to eq('Y:\\Shared\\build\\pkg\\MyNuget.Package.1.0.0.symbols.nupkg')
  end

  it 'should match sample2 with last nupkg mentioned' do
    match = subject.send(:get_nuget_path_of) { sample2 }
    expect(match).to eq('/home/xyz/Shared/build/pkg/MyNuget.Package.1.0.0.symbols.nupkg')
  end

  it 'should match sample3 with last nupkg mentioned' do
    match = subject.send(:get_nuget_path_of) { sample3 }
    expect(match).to eq('/home/xyz/Shared/build/pkg/MyNuget.Package.1.0.0-alpha3.symbols.nupkg')
  end

  it 'should match sample4 with last nupkg mentioned' do
    match = subject.send(:get_nuget_path_of) { sample4 }
    expect(match).to eq('/home/xyz/Shared/build/pkg/MyNuget.Package.1.0.0-alpha.nupkg')
  end

  it 'should match sample5 despite non-ASCII' do
    match = subject.send(:get_nuget_path_of) { sample5 }
    expect(match).to eq('/home/xyz/Shared/build/pkg/Fröken.1.0.0-alpha.nupkg')
  end
end

# testing nuspec task

describe NuspecTask, "when testing public interface" do
  include_context 'pack_config'
  include_context 'path testing'

  it "accepts .nuspec files" do
    expect(NuspecTask.accept?('some.nuspec')).to be true
  end

  let (:cmd) do
    Cmd.new 'NuGet.exe', config.opts()
  end

  subject do
    cmd
  end

  before do
    cmd.extend(ShInterceptor)
    task = NuspecTask.new cmd, config, './spec/testdata/example.nuspec'
    task.execute
  end

  it "should run the correct executable" do
    expect(subject.mono_command).to eq 'NuGet.exe'
  end
  it "should give the correct parameters" do
    expect(subject.mono_parameters).to eq %W[Pack -OutputDirectory #{path 'spec/testdata/pkg'} ./spec/testdata/example.nuspec]
  end
end

# testing project task

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

describe 'encoding functions' do
  it 'should throw InvalidByteSequenceError by default' do
    # http://www.ruby-doc.org/core-2.1.3/String.html#method-i-encode
    begin
      # it's "valid US-ASCII" from the POV of #encode unless
      # #force_encoding is used
      [0xef].pack('C*').force_encoding('US-ASCII').encode 'utf-8'
      fail 'should throw invalid byte sequence error, because it\'s NOT US-ASCII'
    rescue Encoding::InvalidByteSequenceError
      # yep
    end
  end
  it 'should be replaceable' do
    subj =  [0xef].pack('C*').encode 'utf-8', undef: :replace, invalid: :replace, replace: ''
    expect(subj).to eq ''
  end
end
