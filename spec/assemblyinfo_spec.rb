require "fileutils"
require "spec_helper"
require "tempfile"
require "albacore/assemblyinfo"

describe AssemblyInfo do
  let(:input_path) { File.expand_path("spec/assemblyinfo/AssemblyInfo.cs") }
  let(:output_path) { Tempfile.new("AssemblyInfo") }
  let(:content) { File.read(output_path) }
  
  subject(:task) do
    task = AssemblyInfo.new()
    task.output_file = output_path
    task.version = "1.0.0"
    task.file_version = "1.0.0"
    task.informational_version = "1.0.0"
    task.title = "title"
    task.description = "description"
    task.copyright = "copyright"
    task.company_name = "company"
    task.product_name = "product"
    task.trademark = "trademark"
    task.com_visible
    task.com_guid = "00000000-0000-0000-0000-000000000000"
    task.initial_comments = ["//comment"]
    task.namespaces = ["Foo.Bar"]
    task.custom_data = ["whatever"]
    task.custom_attributes = {
      :String => "string", 
      :Null => nil,
      :Literal => false, 
      :Multiple => ["string", true, 0],
      :Named => {:one => "string", :two => true, :three => 0},
      :Mixed => ["string", {:two => true}]
    } 
    task
  end

  after :each do
    FileUtils.rm_rf(output_path)
  end

  context "when using the default engine (csharp)" do
    before :each do
      task.execute
    end

    it "should write the comments first" do
      content.should include("//comment")
    end

    it "should write the custom namespaces" do
      content.should include("using Foo.Bar;")
    end

    it "should write the required namespaces" do
      content.should include("using System.Reflection;")
      content.should include("using System.Runtime.InteropServices;")
    end

    it "should write the title" do
      content.should include("[assembly: AssemblyTitle(\"title\")]")
    end

    it "should write the description" do
      content.should include("[assembly: AssemblyDescription(\"description\")]")
    end

    it "should write the company" do
      content.should include("[assembly: AssemblyCompany(\"company\")]")
    end

    it "should write the product" do
      content.should include("[assembly: AssemblyProduct(\"product\")]")
    end

    it "should write the copyright" do
      content.should include("[assembly: AssemblyCopyright(\"copyright\")]")
    end

    it "should write the trademark" do
      content.should include("[assembly: AssemblyTrademark(\"trademark\")]")
    end

    it "should be COM visible" do
      content.should include("[assembly: ComVisible(true)]")
    end

    it "should write the COM guid" do
      content.should include("[assembly: Guid(\"00000000-0000-0000-0000-000000000000\")]")
    end

    it "should write the version" do
      content.should include("[assembly: AssemblyVersion(\"1.0.0\")]")
    end

    it "should write the file version" do
      content.should include("[assembly: AssemblyFileVersion(\"1.0.0\")]")
    end

    it "should write the informational version" do
      content.should include("[assembly: AssemblyInformationalVersion(\"1.0.0\")]")
    end

    it "should write the custom string attribute" do
      content.should include("[assembly: String(\"string\")]")
    end

    it "should write the custom null attribute" do
      content.should include("[assembly: Null()]")
    end

    it "should write the custom literal attribute" do
      content.should include("[assembly: Literal(false)]")
    end

    it "should write the custom multi-value attribute" do
      content.should include("[assembly: Multiple(\"string\", true, 0)]")
    end

    it "should write the custom multi-value-named attribute" do
      content.should include("[assembly: Named(one = \"string\", two = true, three = 0)]")
    end

    it "should write the custom mixed-multi-value attribute" do
      content.should include("[assembly: Mixed(\"string\", two = true)]")
    end

    it "should write the custom data" do
      content.should include("whatever")
    end
  end

  context "when starting from an input file" do
    before :each do
      task.input_file = input_path
      task.title = nil #=> so it isn't overwritten
      task.execute
    end

    it "should not lose existing comments" do
      content.should include("// General Information about an assembly is controlled through the following")
    end

    it "should not lose existing namespaces" do
      content.should include("using System.Runtime.InteropServices;")
    end

    it "should not lose existing attributes" do
      content.should include("[assembly: AssemblyTitle(\"TestSolution\")]")
    end

    it "should overwrite customized properties" do
      content.should include("[assembly: AssemblyVersion(\"1.0.0\")]")
    end
  end

  context "when using the fsharp engine" do
    before :each do
      task.lang_engine = FSharpEngine.new()
      task.execute
    end

    it "should contain a module definition" do
      content.should include("module AssemblyInfo")
    end

    it "should contain the module definition ending" do
      content.should include("()")
    end

    it "should use open for namespaces" do
      content.should include("open System.Reflection")
    end

    it "should use angle brackets for attributes" do
      content.should include("[<assembly: AssemblyTitle(\"title\")>]")
    end
  end

  context "when using the vbnet engine" do
    before :each do
      task.lang_engine = VbNetEngine.new()
      task.execute
    end

    it "should use imports for namespaces" do
      content.should include("Imports System.Reflection")
    end

    it "should use angle brackets for attributes" do
      content.should include("<assembly: AssemblyTitle(\"title\")>")
    end
  end

  context "when using the cpp cli engine" do
    before :each do
      task.lang_engine = CppCliEngine.new()
      task.execute
    end

    it "should use using for namespaces" do
      content.should include("using namespace System::Reflection;")
    end

    it "should use square brackets for attributes" do
      content.should include("[assembly: AssemblyTitle(\"title\")]")
    end
  end
end
