require 'spec_helper'
require 'albacore/solution'
require 'albacore/project'

describe Albacore::Solution, "when reading solution file" do
  def solution_path
    File.expand_path('../testdata/Project/Project.sln', __FILE__)
  end
  subject do
    Albacore::Solution.new solution_path
  end

  it "should contain Project path in project_paths" do
    expect(subject.project_paths).to include 'Project.fsproj'
  end

  it "should contain Project in projects" do
    project_path = File.expand_path('../testdata/Project/Project.fsproj', __FILE__)
    project = Albacore::Project.new project_path
    expect(subject.projects.map { |p| p.id }).to include project.id
  end

  describe 'public API' do
    it do
      expect(subject).to respond_to :projects
    end
    it do
      expect(subject).to respond_to :project_paths
    end
  end
end
