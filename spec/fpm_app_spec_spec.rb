require 'xsemver'
require 'albacore/app_spec'
require 'albacore/fpm_app_spec'

shared_context 'valid AppSpec' do
  let :spec do
    ::Albacore::AppSpec.new '/a/b/c.appspec', %{
---
title: my.app
project_path: spec/testdata/Project/Project.fsproj
version: 1.2.3
license: MIT
description: my.app implements much wow
uri: https://github.com/Albacore/albacore
category: webserver
}, XSemVer::SemVer.new(5, 6, 7)
  end
end

describe ::Albacore::FpmAppSpec, 'public API' do
  include_context 'valid AppSpec'

  subject do
    ::Albacore::FpmAppSpec.new spec
  end

  it do
    should respond_to :filename
  end

  it 'should know resulting filename' do
    subject.filename.should eq('my.app-5.6.7-1.x86_64.rpm')
  end

  it do
    should respond_to :generate
  end

  it do
    should respond_to :generate_flags
  end
end


describe ::Albacore::FpmAppSpec, 'when generating command from valid AppSpec' do
  include_context 'valid AppSpec'

  subject do
    ::Albacore::FpmAppSpec.new spec
  end

  let :flags do
    subject.generate_flags
  end

  it 'should generate command source' do
    expect(flags['-s']).to eq 'dir'
  end

  it 'should generate command target' do
    expect(flags['-t']).to eq 'rpm'
  end

  it 'should generate command name/title' do
    expect(flags['--name']).to eq 'my.app'
  end

  it 'should generate command description' do
    expect(flags['--description']).to eq 'my.app implements much wow'
  end

  it 'should generate command url' do
    expect(flags['--url']).to eq 'https://github.com/Albacore/albacore'
  end

  it 'should generate command category' do
    expect(flags['--category']).to eq 'webserver'
  end

  it 'should generate command version' do
    expect(flags['--version']).to eq '5.6.7'
  end

  it 'should generate command epoch' do
    expect(flags['--epoch']).to eq 1
  end

  it 'should generate command license' do
    expect(flags['--license']).to eq 'MIT'
  end

  if ::Rake::Win32.windows?
    it 'should generate command "look in this directory" flag' do
      expect(flags['-C']).should match  /^.:\/a\/b$/
    end
  else
    it 'should generate command "look in this directory" flag' do
      expect(flags['-C']).to eq '/a/b'
    end
  end

  it 'should generate command depends' do
    expect(flags['--depends']).to eq 'mono'
  end

  it 'should generate command rpm-digest' do
    expect(flags['--rpm-digest']).to eq 'sha256'
  end
end

describe ::Albacore::FpmAppSpec, 'validation method' do
  include_context 'valid AppSpec'

  subject do
    # TODO: construct
  end
  # TODO: to validate
end

describe ::Albacore::FpmAppSpec, 'when generating command from in-valid AppSpec' do
  let :spec do
    ::Albacore::AppSpec.new 'missing descriptor path', %{
---
title: my.app
project_path: spec/testdata/Project/Project.fsproj
}, XSemVer::SemVer.new(5, 6, 7)
  end

  it 'should raise InvalidAppSpecError' do
    pending 'to be done'
    expect { ::Albacore::FpmAppSpec.new spec }.to raise_error ::Albacore::InvalidAppSpecError
  end
end

describe ::Albacore::FpmAppSpec, 'should never generate nils' do
  let :spec do
    ::Albacore::AppSpec.new 'missing descriptor path', %{
---
title: my.app
project_path: spec/testdata/Project/Project.fsproj
}, XSemVer::SemVer.new(5, 6, 7)
  end

  subject do
    ::Albacore::FpmAppSpec.new spec 
  end

  it 'should not have a license' do
    expect(spec.license).to be nil
  end
  
  it 'that license should never be a FPM parameter' do
    expect(subject.generate_flags.has_key?('--license')).to be false
  end
end

describe ::Albacore::FpmAppSpec::Config do
  %w|files= out= opts no_bundler|.each do |sym|
    it "should respond_to :#{sym}" do
      expect(subject).to respond_to :"#{sym}"
    end
  end
end
