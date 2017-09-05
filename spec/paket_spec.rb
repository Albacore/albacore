require 'albacore/paket'

describe Albacore::Paket, "simple example" do
  let :file do
    %{NUGET
  remote: https://www.nuget.org/api/v2
  specs:
    Aether (6.0)
    Chiron (1.0.1)
      Aether (>= 6.0.0)
      FParsec (>= 1.0.1)
      FSharp.Core (>= 3.1.2.1)
    FParsec (1.0.1)
    FsCheck (1.0.4) - framework: >= net45
    FSharp.Core (4.0.0.1) - redirects: force
    Fuchu (0.6.0.0) - framework: >= net40
    Http.fs-prerelease (2.0.0-alpha1)
      FSharp.Core (>= 3.1.2.1)
    NodaTime (1.3.1)
    NuGet.CommandLine (2.8.5)
}
  end
  describe 'old lockfile' do
    let :references do
      Hash[subject.parse_paket_lock(file.split(/\n|\r\n/))]
    end
    it 'has Aether' do
      expect(references['Aether'].version).to eq '6.0'
    end
    it 'has FParsec' do
      expect(references['FParsec'].version).to eq '1.0.1'
    end
    it 'has Http.fs-prerelease' do
      expect(references['Http.fs-prerelease']).to_not be_nil
      expect(references['Http.fs-prerelease'].version).to eq '2.0.0-alpha1'
    end
    it 'has FsCheck' do
      expect(references['FsCheck']).to_not be_nil
      expect(references['FsCheck'].version).to eq '1.0.4'
      expect(references['FsCheck'].target_framework).to eq 'net45'
    end
    it 'has Fuchu' do
      expect(references['Fuchu']).to_not be_nil
      expect(references['Fuchu'].target_framework).to eq 'net40'
    end
    it 'has FSharp.Core' do
      ref = references['FSharp.Core']
      expect(ref).to_not be_nil
      expect(ref.version).to eq '4.0.0.1'
      expect(ref.redirects).to eq 'force'
    end
  end
end

describe Albacore::Paket, "netcore lockfile" do
  let :path do
    File.expand_path('../testdata/console-core-argu/paket.lock', __FILE__)
  end

  let :references do
    arr = File.open(path, 'r') do |io|
      Albacore::Paket.parse_paket_lock(io.readlines.map(&:chomp))
    end
    Hash[arr]
  end

  it "file exists" do
    expect(File.exists?(path)).to be true
  end

  it "has items" do
    expect(references.length).to_not be_zero
  end

  %w|Argu FSharp.Core|.each do |r|
    it "has #{r}" do
      expect(references[r]).to_not be_nil
    end
  end
end

describe Albacore::Paket, "dependencies file" do
  let :path do
    File.expand_path('../testdata/console-core-argu/paket.dependencies', __FILE__)
  end

  let :references do
    arr = File.open(path, 'r') do |io|
      Albacore::Paket.parse_dependencies_file(io.readlines.map(&:chomp))
    end
    Hash[arr.map{ |x| [x,x] }]
  end

  %w|Argu FSharp.Core|.each do |r|
    it "has #{r}" do
      expect(references[r]).to_not be_nil
    end
  end
end