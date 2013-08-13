require 'spec_helper'
require 'support/sh_interceptor'
require 'albacore'
require 'albacore/task_types/nugets_pack'

shared_context "config" do
  let(:cfg) do 
    cfg = Albacore::NugetsPack::Config.new
    cfg.out = 'src/packages'
    cfg.files = FileList['src/**/*.{csproj,fsproj}']
    cfg
  end
end

describe Albacore::NugetsPack::Cmd, "when calling #execute" do
  
  include_context 'config'

  subject { 
    cmd = Albacore::NugetsPack::Cmd.new nil, 'NuGet.exe', cfg.opts()
    cmd.extend ShInterceptor
    cmd.execute './spec/testdata/example.nuspec'
    cmd
  }

  describe "normal operation" do
    it "should run the correct thing" do
      subject.mono_command.should eq('NuGet.exe')
      subject.mono_parameters.should eq(%w[Pack -OutputDirectory src/packages ./spec/testdata/example.nuspec])
    end
  end

  describe 'packing with -Symbols' do
    before do
      cfg.gen_symbols
    end
    it "should include -Symbols" do
      subject.mono_parameters.should include('-Symbols')
    end  
  end
end 

describe Albacore::NugetsPack::ProjectTask do
  it "rejects .nuspec files" do
    Albacore::NugetsPack::ProjectTask.accept?('some.nuspec').should eq false
  end
end

describe Albacore::NugetsPack::NuspecTask do

  include_context 'config'

  it "accepts .nuspec files" do
    Albacore::NugetsPack::NuspecTask.accept?('some.nuspec').should eq true
  end

  describe "when calling #execute" do
    subject { 
      cmd = Albacore::NugetsPack::Cmd.new nil, 'NuGet.exe', cfg.opts()
      cmd.extend(ShInterceptor)

      task = Albacore::NugetsPack::NuspecTask.new cmd, cfg, './spec/testdata/example.nuspec'
      task.execute
      cmd
    }

    it "should run the correct thing" do
      subject.mono_command.should eq('NuGet.exe')
      subject.mono_parameters.should eq(%W[Pack -OutputDirectory src/packages ./spec/testdata/example.nuspec])
    end
  end

end
