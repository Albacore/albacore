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
    Albacore::NugetsPack::ProjectTask.new "", "", projfile
  end
  it "rejects .nuspec files" do
    Albacore::NugetsPack::ProjectTask.accept?('some.nuspec').should eq false
  end
end
