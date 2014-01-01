require "spec_helper"
require "albacore/nuspec"
require "fileutils"
require "nokogiri"
require "tempfile"

class XmlValidator
  def initialize(xml_file, schema_file)
    @doc    = Nokogiri::XML::Document.parse(File.read(xml_file))
    @schema = Nokogiri::XML::Schema(File.read(schema_file))
  end

  def validate()
    validation = @schema.validate(@doc)
    validation.each { |error| raise error.message }
    return validation.length == 0
  end
end

describe Nuspec do
  let(:output_path) { Tempfile.new("nuspec") }
  let(:content) { File.read(output_path) }
  let(:schema_path) { File.expand_path("spec/nuspec/nuspec.xsd") }
  let(:validator) { XmlValidator.new(output_path, schema_path) }

  subject(:task) do
    task = Nuspec.new()
    task.output_file = output_path
    task.id = "id"
    task.version = "1.0.0"
    task.authors = ["author1", "author2"]
    task.owners = ["owner1", "owner2"]
    task.tags = ["tag1", "tag2"]
    task.title = "title"
    task.description = "description"
    task.summary = "summary"
    task.copyright = "copyright"
    task.release_notes = "notes"
    task.language = "en-US"
    task.license_url = "licenseurl"
    task.project_url = "projecturl"
    task.icon_url = "iconurl"
    task.dependency("depend1", "1.0.0")
    task.file("file1", "lib", "*.xml")
    task.reference("reference1")
    task.framework_assembly("assembly1", "net40")
    task.require_license_acceptance
    task.pretty_formatting
    task
  end

  before :each do
    task.execute
  end

  after :each do
    FileUtils.rm_rf(output_path)
  end

  it "should produce a valid XML file" do
    validator.validate.should be_true
  end

  it "should comma-separate the authors" do
    content.should include("author1, author2")
  end

  it "should comma-separate the owners" do
    content.should include("owner1, owner2")
  end

  it "should space-separate the tags" do
    content.should include("tag1 tag2")
  end
end
