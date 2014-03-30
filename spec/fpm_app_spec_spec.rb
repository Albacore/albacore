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
    flags['-s'].should eq 'dir'
  end

  it 'should generate command target' do
    flags['-t'].should eq 'rpm'
  end

  it 'should generate command name/title' do
    flags['--name'].should eq 'my.app'
  end

  it 'should generate command description' do
    flags['--description'].should eq 'my.app implements much wow'
  end

  it 'should generate command url' do
    flags['--url'].should eq 'https://github.com/Albacore/albacore'
  end

  it 'should generate command category' do
    flags['--category'].should eq 'webserver'
  end

  it 'should generate command version' do
    flags['--version'].should eq '5.6.7'
  end

  it 'should generate command epoch' do
    flags['--epoch'].should eq 1
  end

  it 'should generate command license' do
    flags['--license'].should eq 'MIT'
  end

  it 'should generate command "look in this directory" flag' do
    flags['-C'].should eq '/a/b'
  end

  it 'should generate command depends' do
    flags['--depends'].should eq 'mono'
  end

  it 'should generate command rpm-digest' do
    flags['--rpm-digest'].should eq 'sha256'
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
    spec.license.should be_nil
  end
  
  it 'that license should never be a FPM parameter' do
    subject.generate_flags.has_key?('--license').should be_false
  end
end

describe ::Albacore::FpmAppSpec::Config do
  %w|files= out= opts no_bundler|.each do |sym|
    it "should respond_to :#{sym}" do
      should respond_to :"#{sym}"
    end
  end
end
