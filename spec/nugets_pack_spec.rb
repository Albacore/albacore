# encoding: utf-8

require 'spec_helper'
require 'shared_contexts'
require 'support/sh_interceptor'
require 'albacore'
require 'albacore/task_types/nugets_pack'
require 'albacore/nuget_model'

include ::Albacore::NugetsPack

describe Albacore::NugetsPack::Config, 'when setting #nuget_gem_exe' do
  it 'should be set to path that exists' do
    subject.nuget_gem_exe
    expect(subject.exe).to be_a String
    expect(File.exists?(subject.exe)).to be true
  end

  # this denotes that the user wishes to use the buggy NuGet.exe instead of
  # paket
  it 'should respond to #use_legacy_exe' do
    expect(subject).to respond_to :use_legacy_exe
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
