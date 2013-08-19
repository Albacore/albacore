require 'spec_helper'
require 'albacore/semver'
require 'albacore/project'

describe Albacore::Project, "when loading packages.config" do
  subject {
    p = File.expand_path('../testdata/Project/Project.fsproj', __FILE__)
    #puts "path: #{p}"
    Albacore::Project.new(p)
  }
  let(:nlog) { subject.declared_packages.find { |p| p.id == 'NLog' } }
  it("should have three packages") { subject.declared_packages.length.should == 3 }
  it("should contain NLog") { nlog.should_not be_nil }
  it("should have a four number on NLog") { nlog.version.should eq("2.0.0.2000") }
  it("should have a semver number") { nlog.semver.should eq(Albacore::SemVer.new(2, 0, 0)) }
end

describe Albacore::Project, "when reading project file" do
  subject {
    p = File.expand_path('../testdata/Project/Project.fsproj', __FILE__)
    Albacore::Project.new(p)
  }
  let(:library1) { subject.included_files.find { |p| p.include == 'Library1.fs' } }
  it("should contain library1") { library1.should_not be_nil }

end
