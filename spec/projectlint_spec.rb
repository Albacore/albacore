require 'albacore'
require 'albacore/tasks/projectlint'

class ProjectLintReturn
    attr_reader :failed, :failure_message
    def initialize(failed, message=nil)
        @failed = failed
        @failure_message = message
    end
end

def project_lint_on(name, path, ignores=nil)
  root_folder = File.expand_path(File.join(File.dirname(__FILE__),'projectlint'))
  f = Albacore::Tasks::ProjectLint.new name do |c|
    c.project = File.join(root_folder, path)
      if ignores
        c.ignores = ignores
      end
  end
  begin
    f.execute
  rescue Exception => e
    return ProjectLintReturn.new(true, e.message)
  end
  return ProjectLintReturn.new(false)
end

describe "when supplying a csproj file with files added but not present on the filesystem" do
  before(:all) { @f = project_lint_on(:first, File.join( 'added_but_not_on_filesystem', 'aproject.csproj')) }

  it("should fail") { expect(@f.failed).to be true }

  it("should report failure") { expect(@f.failure_message).to include "-" }

  it("should report file.cs") { expect(@f.failure_message).to include 'File.cs' }

  it("should report Image.txt") { expect(@f.failure_message).to include 'Image.txt' }

  it("should report MyHeavy.heavy") { expect(@f.failure_message).to include 'MyHeavy.heavy' }

  it("should report Schema.xsd") { expect(@f.failure_message).to include 'Schema.xsd' }

  it("should report SubFolder/AnotherFile.cs") { expect(@f.failure_message).to include 'AnotherFile.cs' }

  it("should not report linked files") { expect(@f.failure_message).to_not include 'SomeFile.cs' }
end

describe "when supplying a correct csproj file with files added and present on the filesystem" do
  
  before(:all) { @f = project_lint_on(:second, File.join( 'correct', 'aproject.csproj')) }

  it("should not fail") {
    expect(@f.failed).to be false
  }
  it("no message") { expect(@f.failure_message).to be nil } 
end

describe "when supplying a csproj file with files not added but present on the filesystem" do
  before(:all) { @f = project_lint_on(:third, File.join( 'on_filesystem_but_not_added', 'aproject.csproj')) }

  it("should fail") { expect(@f.failed).to be true }

  it("should report failure") { expect(@f.failure_message).to include '+' }

  it("should report file.cs") { expect(@f.failure_message).to include 'File.cs' }

  it("should report Image.txt") { expect(@f.failure_message).to include 'Image.txt' }
end


describe "when supplying a csproj files with files on filesystem ignored" do
  before(:all) {
    @f = project_lint_on(:fourth, File.join('on_filesystem_but_not_added', 'aproject.csproj'), [/.*\.txt$/, /.*\.cs$/])
  }

  it("should not fail") { expect(@f.failed).to be false }
end
