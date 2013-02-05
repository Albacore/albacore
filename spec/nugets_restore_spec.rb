require 'albacore'
require 'albacore/nugets_restore'

module ShInterceptor
  def sh wd, *args
    @received = args
  end
  def received_wd
    @wd || nil
  end
  def received_sh_args
    @received || []
  end
end

describe Albacore::NugetsRestore::Cmd, "when calling #execute" do
  subject { 
    cfg = Albacore::NugetsRestore::Config.new
    cfg.add_parameter '-Source' 
    cfg.add_parameter 'http://localhost:8081'
    cmd = Albacore::NugetsRestore::Cmd.new nil, 'NuGet.exe', 'NLog', 'src/packages', cfg.parameters
    cmd.extend(ShInterceptor)
    cmd.execute
    cmd
  }
  it "should run the correct thing" do
    expected = %W["NuGet.exe" "install" "NLog" "-OutputDirectory" "src/packages" "-Source" "http://localhost:8081"].join(' ')
    zipped = [expected].zip(subject.received_sh_args)
    zipped.each{|i1, i2| i1.should eq(i2)}
  end
end 
