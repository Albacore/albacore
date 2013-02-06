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
    expected = %W["NuGet.exe" "install" "src/Proj/packages.config" "-OutputDirectory" "src/packages" "-Source" "http://localhost:8081"].join(' ')
    zipped = [expected].zip(subject.received_args)
    zipped.each{|i1, i2| i1.should eq(i2)}
  end
end 
describe Albacore::NugetsRestore::Cmd, "when calling #execute" do
  subject { 
    cfg = Albacore::NugetsRestore::Config.new
    cfg.username = 'usr'
    cfg.password = 'pass'
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

  it "should have called #system_control" do
    subject.system_control_calls.should eq(1)
  end
end
