require 'albacore'

describe Albacore::NugetsRestore::Cmd do
  subject { Albacore::NugetsRestore::Cmd.new nil, "NuGet.exe", "NLog", "packages/", %W{-Source http://albacorebuild.net} }
  it("should produce command") {
     

  }
end
