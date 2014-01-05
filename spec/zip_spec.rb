require "spec_helper"
require "fileutils"
require "albacore/zipdirectory"
require "albacore/unzip"

describe ZipDirectory do
  let(:output_path) { File.join(Dir.mktmpdir(), "test.zip") }
  let(:unzip_path)  { Dir.mktmpdir() }

  let(:unzip) do
    unzip = Unzip.new()
    unzip.file = output_path
    unzip.destination = unzip_path
    unzip
  end    

  subject(:task) do
    task = ZipDirectory.new()
    task.flatten
    task.dirs = ["spec/zip/foo"]
    task.files = ["spec/zip/baz.txt"]
    task.output_path = output_path
    task
  end

  after :each do
    FileUtils.rm_rf(output_path)
    FileUtils.rm_rf(unzip_path)
  end

  context "when zipping" do
    before :each do
      task.execute()
      unzip.execute()
    end
    
    it "should make a zip" do
      File.exist?(output_path).should be_true
    end

    it "should zip the additional file" do
      File.exist?(File.join(unzip_path, "baz.txt")).should be_true
    end

    it "should zip the root file" do
      File.exist?(File.join(unzip_path, "foo.txt")).should be_true
    end

    it "should zip the subfolder" do
      File.exist?(File.join(unzip_path, "bar")).should be_true
    end

    it "should zip the subfolder file" do
      File.exist?(File.join(unzip_path, "bar/bar.txt")).should be_true
    end
  end

  context "when zipping with string exclusions" do
    before :each do
      task.exclusions = ["spec/zip/foo/bar/bar.txt"]
      task.execute()
      unzip.execute()
    end

    it "should skip matching files" do
      File.exist?(File.join(unzip_path, "bar/bar.txt")).should be_false
    end
  end

  context "when zipping with regex exclusions" do
    before :each do
      task.exclusions = [/bar/]
      task.execute()
      unzip.execute()
    end
      
    it "should skip matching files" do
      File.exist?(File.join(unzip_path, "bar/bar.txt")).should be_false
    end
  end

  context "when zipping with glob exclusions" do
    before :each do
      task.exclusions = ["**/bar/*"]
      task.execute()
      unzip.execute()
    end

    it "should skip matching files" do
      File.exist?(File.join(unzip_path, "bar/bar.txt")).should be_false
    end
  end

  context "without flatten" do
    it "should zip" do
      pending("needs some thought")
    end
  end
end
