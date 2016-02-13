# encoding: utf-8

require 'albacore/paths'

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

shared_context 'package_metadata_dsl' do
  let :m do
    subject.metadata
  end

  def self.has_value sym, e
    it "should have overridden #{sym}, to be #{e}" do
      expect(m.send(sym)).to eq e
    end
  end

  def self.has_dep name, version
    it "has dependency on '#{name}'" do
      expect(m.dependencies.has_key?(name)).to be true
    end
    it "overrode dependency on '#{name}'" do
      expect(m.dependencies[name].version).to eq version
    end
  end

  def self.has_not_dep name
    it "does not have a dependency on #{name}" do
      expect(m.dependencies.has_key?(name)).to be false
    end
  end

  def self.has_file src, target, exclude = nil
    src, target = norm(src), norm(target)
    it "has file[#{src}] (should not be nil)" do
      file = subject.files.find { |f| f.src == src }
     #  puts "## ALL FILES ##"
     #  subject.files.each do |f|
     #    puts "subject.files: #{subject.files}, index of: #{subject.files.find_index { |f| f.src == src }}"
     #    puts "#{f.inspect}"
     #  end
      expect(file).to_not be nil
    end

    it "has file[#{src}].target == '#{target}'" do
      file = subject.files.find { |f| f.src == src }
      expect(file.target).to eq target
    end
  end

  def self.has_not_file src
    src = norm src
    it "has not file[#{src}]" do
      file = subject.files.find { |f| f.src == src }
      expect(file).to be nil
    end
  end

  def self.norm str
    Albacore::Paths.normalise_slashes str
  end
end

