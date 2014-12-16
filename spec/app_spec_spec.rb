require 'xsemver'
require 'albacore/app_spec'

describe ::Albacore::AppSpec, 'public API with defaults' do
  subject do
    ::Albacore::AppSpec.new 'missing-path', %{
---
title: superapp.now
project_path: spec/testdata/Project/Project.fsproj
}
  end

  %w|title description uri category version license dir_path to_s|.map { |w| :"#{w}" }.each do |s|
    it "should respond to ##{s}" do
      expect(subject).to respond_to s
    end

    it "should be possible to always call ##{s}" do
      subject.method(s).call
    end
  end

  def teamcity?
    !!ENV['TEAMCITY_VERSION']
  end

  it 'should have correct title' do
    expect(subject.title).to eq 'superapp.now'
  end

  it 'should have nil license' do
    expect(subject.license).to be_nil
  end

  it 'should have nil description' do
    expect(subject.description).to be_nil
  end

  it 'should never have nil uri, since we\'re in the albacore git repo and it defaults to the current repo' do
    expect(subject.uri).to include 'albacore.git' unless teamcity? # teamcity doesn't keep git folder
  end

  it 'should have "apps" category, since it\'s not specified anywhere' do
    expect(subject.category).to eq 'apps'
  end

  it 'should have a nil version' do
    expect(subject.version).to eq('1.0.0')
  end

  it 'should have non-nil #bin_folder' do
    expect(subject.bin_folder).to_not be_nil
  end

  it 'should have non-nil #conf_folder' do
    expect(subject.conf_folder).to_not be_nil
  end

  it 'should have non-nil #contents' do
    expect(subject.contents).to_not be_nil
  end

  it 'should have a #contents that responds to #each' do
    expect(subject.contents).to respond_to :each
  end
end

describe ::Albacore::AppSpec, 'public API with required fields' do
  subject do
    ::Albacore::AppSpec.new 'missing-.appspec-path', %{
---
title: superapp.now
project_path: spec/testdata/Project/Project.fsproj
}
  end
end

describe ::Albacore::AppSpec, 'when getting version from semver' do
  subject do
    ::Albacore::AppSpec.new 'missing-.appspec-path', %{
---
title: zeeky
version: 4.5.6
project_path: spec/testdata/Project/Project.fsproj
}, XSemVer::SemVer.new(1,2,3)
  end

  it 'should take version from the semver first' do
    expect(subject.version).to eq '1.2.3'
  end
end

describe ::Albacore::AppSpec, 'when getting version from yaml' do
  subject do
    ::Albacore::AppSpec.new 'missing-.appspec-path', %{
---
title: smurfs.abound
version: 4.5.6
project_path: spec/testdata/Project/Project.fsproj
}, nil
  end

  it 'should take version from the semver first' do
    expect(subject.version).to eq '4.5.6'
  end
end

describe ::Albacore::AppSpec, 'when giving invalid project path' do
  it 'should raise ArgumentError when path doesn\'t exist' do
    expect {
      ::Albacore::AppSpec.new 'missing-.appspec-path', %{---
project_path: path/not/existent/proj.fsproj}, nil
    }.to raise_error(ArgumentError)
  end

  it 'should raise ArgumentError when no value given' do
    expect {
      ::Albacore::AppSpec.new 'missing-.appspec-path', %{---
title: my.project}, nil
    }.to raise_error(ArgumentError)
  end
end

describe ::Albacore::AppSpec, 'when fetching ALL data from Project.fsproj' do
  let :project_path do
    'spec/testdata/Project/Project.appspec'
  end

  subject do
    ::Albacore::AppSpec.load project_path
  end

  it 'should find the directory of the project' do
    # this also means it found a project and successfully parsed its project
    # definition
    expect(subject.proj.proj_path_base).to include File.dirname(project_path)
  end

  it 'should have the title' do
    expect(subject.title).to eq 'project'
    expect(subject.title_raw).to eq 'Project'
  end

  it 'should have no license' do
    expect(subject.license).to be_nil
  end
end
