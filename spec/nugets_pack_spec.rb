require 'albacore'
require 'albacore/nugets_pack'
require 'albacore/dsl'
require 'sh_interceptor'

class NGConf
  self.extend Albacore::DSL 
end

describe Albacore::NugetsPack::Cmd, "when calling #execute" do
  subject { 
    cfg = Albacore::NugetsPack::Config.new
    cfg.out = 'src/packages'
    cfg.files = FileList['src/**/*.{csproj,fsproj}']

    cmd = Albacore::NugetsPack::Cmd.new nil, 'NuGet.exe', cfg.opts()
    cmd.extend(ShInterceptor)
    cmd.execute 'src/some.nuspec'
    cmd
  }

  it "should run the correct thing" do
    expected_args = %W["NuGet.exe" "pack" "-OutputDirectory" "src/packages" "src/some.nuspec"]
    expected_args.unshift '"mono"' unless ::Rake::Win32.windows?
    expected_args = expected_args.to_a.join(' ')
    
    subject.received_args[0].should eq expected_args
  end
end 

describe Albacore::NugetsPack::ProjectTask do
  it "reject .nuspec files" do
    Albacore::NugetsPack::ProjectTask.accept?('some.nuspec').should eq false
  end
end

describe Albacore::NugetsPack::NuspecTask do

  it "accepts .nuspec files" do
    Albacore::NugetsPack::NuspecTask.accept?('some.nuspec').should eq true
  end

  describe "when calling #execute" do
    subject { 
      cfg = Albacore::NugetsPack::Config.new
      cfg.out = 'src/packages'
      cfg.files = FileList['src/**/*.{csproj,fsproj,nuspec}']

      cmd = Albacore::NugetsPack::Cmd.new nil, 'NuGet.exe', cfg.opts()
      cmd.extend(ShInterceptor)

      task = Albacore::NugetsPack::NuspecTask.new cmd, cfg, 'src/some.nuspec'
      task.execute
      cmd
    }

    it "should run the correct thing" do
      expected_args = %W["NuGet.exe" "pack" "-OutputDirectory" "src/packages" "src/some.nuspec"]
      expected_args.unshift '"mono"' unless ::Rake::Win32.windows?
      expected_args = expected_args.to_a.join(' ')
      
      subject.received_args[0].should eq expected_args
    end
  end

end
