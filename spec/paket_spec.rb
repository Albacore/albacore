require 'albacore/paket'

describe Albacore::Paket do
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
  describe 'parsing paket.lock file' do
    let :references do
      Hash[subject.parse_paket_lock(file.split(/\n|\r\n/))]
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
