require 'spec_helper'
require 'support/sh_interceptor'
require 'albacore'
require 'albacore/task_types/nugets_pack'

shared_context "pack_config" do
  let :id do
    'Sample.Nuget'
  end
  let :curr do
    File.dirname(__FILE__)
  end
  let :config do
    cfg = Albacore::NugetsPack::Config.new
    cfg.target        = 'net40'
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
      m.release_notes = %{
v10.0.0:
  - Some notes
}
      m.require_license_acceptance = false

      m.add_dependency 'Abc.Package', '>= 1.0.2'
      m.add_framework_dependency 'System.Transactions', '4.0.0'
    end
    cfg.gen_symbols # files: *.{pdb,dll,all compiled files}
    cfg
  end
end

describe Albacore::NugetsPack::Cmd, "when calling #execute" do
  include_context 'pack_config'

  subject do
    Albacore::NugetsPack::Cmd.new 'NuGet.exe', config.opts()
  end

  let :sample1 do
<<EXAMPLE_OUTPUT
Attempting to build package from 'MyNuget.Package.nuspec'.
Successfully created package 'Y:/Shared/build/pkg\\MyNuget.Package.1.0.0.nupkg'.
Successfully created package 'Y:/Shared/build/pkg\\MyNuget.Package.1.0.0.symbols.nupkg'.
EXAMPLE_OUTPUT
  end

  let :sample2 do
<<EXAMPLE_OUTPUT
Attempting to build package from 'MyNuget.Package.nuspec'.
Successfully created package '/home/xyz/Shared/build/pkg/MyNuget.Package.1.0.0.nupkg'.
Successfully created package '/home/xyz/Shared/build/pkg/MyNuget.Package.1.0.0.symbols.nupkg'.
EXAMPLE_OUTPUT
  end

  it "should match sample1 with last nupkg mentioned" do
    match = subject.send(:get_nuget_path_of) { sample1 }
    match.should eq('Y:/Shared/build/pkg\\MyNuget.Package.1.0.0.symbols.nupkg')
  end

  it 'should match sample2 with last nupkg mentioned' do
    match = subject.send(:get_nuget_path_of) { sample2 }
    match.should eq('/home/xyz/Shared/build/pkg/MyNuget.Package.1.0.0.symbols.nupkg')
  end
end


# testing the command for nuget

describe Albacore::NugetsPack::Cmd, "when calling #execute" do
  
  include_context 'pack_config'
  include_context 'path testing'

  let :cmd do
    Albacore::NugetsPack::Cmd.new 'NuGet.exe', config.opts()
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
    it "should run the correct executable" do
      subject.mono_command(0).should eq('NuGet.exe')
    end
    it "should include the correct parameters" do
      subject.mono_parameters(0).should eq(%W[Pack -OutputDirectory #{path 'spec/testdata/pkg'} ./spec/testdata/example.nuspec])
    end
  end

  describe "second invocation" do
    it "should include -Symbols" do
      subject.mono_parameters(1).should eq(%W[Pack -OutputDirectory #{path 'spec/testdata/pkg'} -Symbols ./spec/testdata/example.symbols.nuspec])
    end
  end
end

describe Albacore::NugetsPack::NuspecTask, "when testing public interface" do
  include_context 'pack_config'
  include_context 'path testing'

  it "accepts .nuspec files" do
    Albacore::NugetsPack::NuspecTask.accept?('some.nuspec').should be_true
  end

  let (:cmd) do
    Albacore::NugetsPack::Cmd.new 'NuGet.exe', config.opts()
  end

  subject do
    cmd
  end

  before do
    cmd.extend(ShInterceptor)
    task = Albacore::NugetsPack::NuspecTask.new cmd, config, './spec/testdata/example.nuspec'
    task.execute
  end

  it "should run the correct executable" do
    subject.mono_command.should eq('NuGet.exe')
  end
  it "should give the correct parameters" do
    subject.mono_parameters.should eq(%W[Pack -OutputDirectory #{path 'spec/testdata/pkg'} ./spec/testdata/example.nuspec])
  end
end

describe Albacore::NugetsPack::ProjectTask, "when testing public interface" do
  let :projfile do
    curr = File.dirname(__FILE__)
    File.join curr, "testdata", "Project.fsproj"
  end
  it "can be created" do
    Albacore::NugetsPack::ProjectTask.new(Map.new(:files => [projfile]))
  end
  it "rejects .nuspec files" do
    Albacore::NugetsPack::ProjectTask.accept?('some.nuspec').should eq false
  end
end

describe Albacore::NugetsPack::ProjectTask, "creating nuget from proj file" do
  let(:cmdo) { Hash.new }

  include_context 'pack_config'

  subject do
    Albacore::NugetsPack::ProjectTask.new(config.opts()) do |cmd|
      cmd.extend ShInterceptor
      cmdo[:cmd] = cmd
    end
  end 

  before :each do
    subject.execute
  end

  it "should have generated a nuspec" do
    cmdo[:cmd].mono_parameters(0)[-1].should include('Sample.Nuget.nuspec')
  end

  it "should have generated a symbol nuspec" do
    cmdo[:cmd].mono_parameters(1)[-1].should include('Sample.Nuget.symbols.nuspec')
  end
end
