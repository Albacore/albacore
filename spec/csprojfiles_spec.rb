require 'spec_helper'
require 'albacore/csprojfiles'
require 'csprojfilestestdata'
require 'csprojfiles_patch'

Albacore.configure do |config|
  config.log_level = :verbose
end

describe CsProjFiles, "when supplying a csproj file with files added but not present on the filesystem" do
  before :all do
    @testdata = CsProjFilesTestData.new
    @f = CsProjFiles.new
    @f.project = @testdata.added_but_not_on_filesystem
    @f.execute
  end

  it "should fail" do
    @f.failed.should be_true
  end

  it "should report failure" do
    @f.failure_message.should include("-")
  end

  it "should report file.cs" do
    @f.failure_message.should include('File.cs')
  end

  it "should report Image.txt" do
    @f.failure_message.should include('Image.txt')
  end

  it "should report MyHeavy.heavy" do
    @f.failure_message.should include('MyHeavy.heavy')
  end

  it "should report Schema.xsd" do
    @f.failure_message.should include('Schema.xsd')
  end

  it "should report SubFolder/AnotherFile.cs" do
    @f.failure_message.should include('AnotherFile.cs')
  end

  it "should not report linked files" do
    @f.failure_message.should_not include('SomeFile.cs')
  end
end

describe CsProjFiles, "when supplying a correct csproj file with files added and present on the filesystem" do
  before :all do
    @testdata = CsProjFilesTestData.new
    @f = CsProjFiles.new
    @f.project = @testdata.correct
    @f.execute
  end

  it "should not fail" do
    @f.failed.should be_false
  end

end

describe CsProjFiles, "when supplying a csproj file with files not added but present on the filesystem" do
  before :all do
    @testdata = CsProjFilesTestData.new
    @f = CsProjFiles.new
    @f.project = @testdata.on_filesystem_but_not_added
    @f.execute
  end

  it "should fail" do
    @f.failed.should be_true
  end

  it "should report failure" do
    @f.failure_message.should include("+")
  end

  it "should report file.cs" do
    @f.failure_message.should include('File.cs')
  end

  it "should report Image.txt" do
    @f.failure_message.should include('Image.txt')
  end
end


describe CsProjFiles, "when supplying a csproj files with files on filesystem ignored" do
  before :all do
    @testdata = CsProjFilesTestData.new
    @f = CsProjFiles.new
    @f.project = @testdata.on_filesystem_but_not_added
    @f.ignore_files = [/.*\.txt$/, /.*\.cs$/] # all of the files
    @f.execute
  end

  it "should not fail" do
    @f.failed.should be_false
  end

end