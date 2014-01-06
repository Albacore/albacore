require "spec_helper"
require "fileutils"

describe Output do
  let(:from) { File.expand_path("spec/output") }
  let(:to) { Dir.mktmpdir() }
  let(:erb) { File.read("#{to}/erb.txt") }

  subject(:task) do
    task = Output.new()
    task.from from
    task.to to
    task.dir "foo"
    task.dir "foo", :as => "baz"
    task.file "baz.txt"
    task.file "bar/bar.txt"
    task.file "bar/bar.txt", :as => "bar.txt"
    task.erb "erb.txt", :locals => {:name => "world"}
    task.erb "erb.txt", :as => "hello.config"
    task
  end

  after :each do
    FileUtils.rm_rf(to)
  end

  context "all the basic scenarios" do
    before :each do
      File.write("#{to}/overwrite.txt", "")
      task.execute
    end

    it "should remove the existing file" do
      File.exist?("#{to}/overwrite.txt").should be_false
    end
    
    it "should copy the folder" do
      Dir.exist?("#{to}/foo").should be_true
    end

    it "should copy the subfolder" do
      Dir.exist?("#{to}/foo/foo").should be_true
    end

    it "should copy the subfolder file" do 
      File.exist?("#{to}/foo/foo/foo.txt").should be_true
    end

    it "should copy and rename the folder" do
      Dir.exist?("#{to}/baz").should be_true
    end

    it "should copy the single file" do
      File.exist?("#{to}/baz.txt").should be_true
    end

    it "should copy the file inside it's subfolder" do
      File.exist?("#{to}/bar/bar.txt").should be_true
    end

    it "should copy and rename the file out of the subfolder" do
      File.exist?("#{to}/bar.txt").should be_true
    end

    it "should copy and rename the erb template file" do
      File.exist?("#{to}/hello.config").should be_true
    end

    it "should fill in the erb template" do
      erb.should include("Hello, world!")
    end
  end

  context "when preserving the destination" do
    before :each do
      File.write("#{to}/preserve.txt", "")
      task.preserve
      task.execute
    end

    it "should preserve the existing file" do
      File.exist?("#{to}/preserve.txt").should be_true
    end
  end
end
