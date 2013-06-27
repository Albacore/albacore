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
    cfg.files = FileList['testdata/**/*.{csproj,fsproj}']

    cmd = Albacore::NugetsPack::Cmd.new nil, 'NuGet.exe', cfg.opts()
    cmd.extend(ShInterceptor)
    cmd.execute 'some.nuspec'
    cmd
  }

  it "should run the correct thing" do
		s = ::Rake::Win32.windows?() ? "\\" : "/" 
    expected_args = %W["NuGet.exe" "pack" "-OutputDirectory" "src/packages" "some.nuspec"]
    expected_args.unshift '"mono"' unless ::Rake::Win32.windows?
    expected_args = expected_args.to_a.join(' ')
    
    subject.received_args[0].should eq expected_args
  end
end 
