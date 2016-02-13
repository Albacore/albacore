# encoding: utf-8

class ConfigFac
  def self.create id, curr, gen_symbols = true
    cfg = Albacore::NugetsPack::Config.new
    cfg.target        = 'mono32'
    cfg.configuration = 'Debug'
    cfg.files         = Dir.glob(File.join(curr, 'testdata', 'Project', '*.fsproj'))
    cfg.out           = 'spec/testdata/pkg'
    cfg.exe           = 'NuGet.exe'
    cfg.with_metadata do |m|
      m.id            = id
      m.authors       = 'haf'
      m.owners        = 'haf owner'
      m.description   = 'a nice lib'
      m.language      = 'Danish'
      m.project_url   = 'https://github.com/haf/Reasonable'
      m.license_url   = 'https://github.com/haf/README.md'
      m.version       = '0.2.3'
      m.release_notes = %{
v10.0.0:
  - Some notes
}
      m.require_license_acceptance = false

      m.add_dependency 'Abc.Package', '>= 1.0.2'
      m.add_framework_dependency 'System.Transactions', '4.0.0'
    end
    cfg.gen_symbols if gen_symbols # files: *.{pdb,dll,all compiled files}
    cfg
  end
end

shared_context 'pack_config' do
  let :id do
    'Sample.Nuget'
  end
  let :curr do
    File.dirname(__FILE__)
  end
  let :config do
    ConfigFac.create id, curr, true
  end
end

shared_context 'pack_config no symbols' do
  let :id do
    'Sample.Nuget'
  end
  let :curr do
    File.dirname(__FILE__)
  end
  let :config do
    ConfigFac.create id, curr, false
  end
end
