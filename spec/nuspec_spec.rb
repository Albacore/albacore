require 'fileutils'
require 'spec_helper.rb'
require 'albacore/nuspec.rb'
require 'support/nokogiri_validator'

describe Nuspec do
  let(:working_dir) do
    wd = File.expand_path(File.join(File.dirname(__FILE__), 'support/nuspec/output')) 
    FileUtils.mkdir(wd) unless File.exist?(wd)
    wd
  end
  let(:nuspec_output) { File.join(working_dir, 'nuspec_test.nuspec') }
  let(:schema_file) { File.expand_path(File.join(working_dir, '../', 'nuspec.xsd')) }

  describe 'when creating a file with minimum requirements' do
    let(:nuspec) do
      nuspec = Nuspec.new
      nuspec.id="nuspec_test"
      nuspec.output_file = "nuspec_test.nuspec"
      nuspec.version = "1.2.3"
      nuspec.authors = "Author Name"
      nuspec.description = "test_xml_document"
      nuspec.copyright = "copyright 2011"
      nuspec.working_directory = working_dir
      nuspec
    end

    before do
      nuspec.execute
    end

    it "should produce the nuspec xml" do
      File.exist?(nuspec_output).should be_true
    end

    it "should produce a valid xml file" do
      is_valid = XmlValidator.validate(nuspec_output, schema_file)
      is_valid.should be_true
    end
  end

  describe "file targets" do
    let(:dll) { File.expand_path(File.join(working_dir, '../', 'somedll.dll')) }

    let(:nuspec) do
      nuspec = Nuspec.new
      nuspec.id="nuspec_test"
      nuspec.output_file = "nuspec_test.nuspec"
      nuspec.title = "Title"
      nuspec.version = "1.2.3"
      nuspec.authors = "Author Name"
      nuspec.description = "test_xml_document"
      nuspec.copyright = "copyright 2011"
      nuspec.working_directory = working_dir
      nuspec.file(dll, "lib")
      nuspec.file(dll, "lib\\net40", "*.xml")
      nuspec
    end

    before do
      nuspec.execute
      File.open(nuspec_output, "r") do |f|
        @filedata = f.read
      end
    end

    it "should produce a valid nuspec file" do
      is_valid = XmlValidator.validate(nuspec_output, schema_file)
      is_valid.should be_true
    end

    it "should contain the file and it's target" do
      @filedata.downcase.should include("<file src='#{dll}' target='lib'/>".downcase)
    end

    it "should contain the file and it's target and an exclude" do
      @filedata.should include("<file exclude='*.xml' src='#{dll}' target='lib\\net40'/>")
    end
  end
  
  describe "references" do
    let(:dll) { File.expand_path(File.join(working_dir, '../', 'somedll.dll')) }

    let(:nuspec) do
      nuspec = Nuspec.new
      nuspec.id="nuspec_test"
      nuspec.output_file = "nuspec_test.nuspec"
      nuspec.title = "Title"
      nuspec.version = "1.2.3"
      nuspec.authors = "Author Name"
      nuspec.description = "test_xml_document"
      nuspec.copyright = "copyright 2011"
      nuspec.working_directory = working_dir
      nuspec.reference("testFile1")
      nuspec.reference("testFile2")
      nuspec
    end

    before do
      nuspec.execute
      File.open(nuspec_output, "r") do |f|
        @filedata = f.read
      end
    end

    it "should produce a valid nuspec file" do
      is_valid = XmlValidator.validate(nuspec_output, schema_file)
      is_valid.should be_true
    end

    it "should contain references tag" do
	  @filedata.downcase.should include("<references>".downcase)
	end
	
    it "should contain references closing tag" do
	  @filedata.downcase.should include("</references>".downcase)
	end
	
    it "should contain the test file 1" do
      @filedata.downcase.should include("<reference file='testFile1'/>".downcase)
    end

    it "should contain the 2nd test file" do
      @filedata.downcase.should include("<reference file='testFile2'/>".downcase)
    end
  end
end
