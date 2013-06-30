require 'spec_helper'
require 'albacore'
require 'albacore/nugets_restore'
require 'albacore/dsl'
require 'sh_interceptor'

class NGConf
  self.extend Albacore::DSL 
end

describe Albacore::NugetsRestore::Cmd, "when calling #execute" do
  subject { 
    cfg = Albacore::NugetsRestore::Config.new
    cfg.out = 'src/packages'
    cfg.add_parameter '-Source' 
    cfg.add_parameter 'http://localhost:8081'

    cmd = Albacore::NugetsRestore::Cmd.new nil, 
            'NuGet.exe', 
            cfg.opts_for_pkgcfg('src/Proj/packages.config')
    cmd.extend(ShInterceptor)
    cmd.execute
    cmd
  }

  it "should run the correct thing" do
		s = ::Rake::Win32.windows?() ? "\\" : "/" 
    mono = ::Rake::Win32.windows?() ? '' : '"mono"'
    tmp = %W["NuGet.exe" "install" "src#{s}Proj#{s}packages.config" "-OutputDirectory" "src/packages" "-Source" "http://localhost:8081"]
    expected = mono == '' ? tmp : tmp.unshift(mono)
    expected = expected.to_a.join(' ')
    expected.should eq(subject.received_args[0])
  end
end 
