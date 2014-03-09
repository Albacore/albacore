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

  %w|title description uri category version license dir_path|.map { |w| :"#{w}" }.each do |s|
    it "should respond to ##{s}" do
      subject.should respond_to s
    end

    it "should be possible to always call ##{s}" do
      subject.method(s).call
    end
  end

  it 'should have correct title' do
    subject.title.should eq 'superapp.now'
  end

  it 'should have nil license' do
    subject.license.should be_nil
  end

  it 'should have nil description' do
    subject.description.should be_nil
  end

  it 'should never have nil uri, since we\'re in the albacore git repo and it defaults to the current repo' do
    subject.uri.should include 'albacore.git'
  end

  it 'should have "apps" category, since it\'s not specified anywhere' do
    subject.category.should eq 'apps'
  end

  it 'should have a nil version' do
    subject.version.should be_nil
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

  # TODO: create a spike that actually works and document what is required here  


end

describe ::Albacore::AppSpec, 'when getting version from semver' do
  subject do
    ::Albacore::AppSpec.new 'missing-.appspec-path', %{
---
title: 
version: 4.5.6
project_path: spec/testdata/Project/Project.fsproj
}, XSemVer::SemVer.new(1,2,3)
  end

  it 'should take version from the semver first' do
    subject.version.should eq '1.2.3'
  end
end

describe ::Albacore::AppSpec, 'when getting version from semver' do
  subject do
    ::Albacore::AppSpec.new 'missing-.appspec-path', %{
---
title: 
version: 4.5.6
project_path: spec/testdata/Project/Project.fsproj
}, nil
  end

  it 'should take version from the semver first' do
    subject.version.should eq '4.5.6'
  end
end
