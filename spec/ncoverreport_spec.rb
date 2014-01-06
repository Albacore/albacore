require "spec_helper"

describe NCoverReport do
  subject(:task) do
    task = NCoverReport.new()
    task.extend(SystemPatch)
    task.command = "ncover"
    task.coverage_files = ["a.xml", "b.xml"]
    task.filters = [NCover::AssemblyFilter.new(:filter => "filter")]
    task.reports = [NCover::FullCoverageReport.new(:output_path => "output")]
    task.required_coverage = [NCover::BranchCoverage.new()]
    task
  end

  let(:cmd) { task.system_command }

  before :each do
    task.execute
  end

  it "should use the command" do
    cmd.should include("ncover")
  end

  it "should cover the files" do 
    cmd.should include("\"a.xml\" \"b.xml\"")
  end

  it "should create a filter" do
    cmd.should include("//cf \"filter\":Assembly:false:false")
  end

  it "should create a report" do
    cmd.should include("//or FullCoverageReport:Html:\"output\"")
  end

  it "should create a coverage requirement" do
    cmd.should include("//mc BranchCoverage:0:View")
  end
end

describe NCover::FullCoverageReport do
  subject(:report) { NCover::FullCoverageReport.new(:output_path => "output") }
  let(:opts) { report.get_report_options() }

  it "should be a full coverage html report" do
    opts.should include("FullCoverageReport:Html:\"output\"")
  end
end

describe NCover::SummaryReport do
  subject(:report) { NCover::SummaryReport.new(:output_path => "output") }
  let(:opts) { report.get_report_options() }

  it "should be a summary html report" do
    opts.should include("Summary:Html:\"output\"")
  end
end  

describe NCover::BranchCoverage do
  subject(:cover) { NCover::BranchCoverage.new() }
  let(:opts) { cover.get_coverage_options() }

  it "should be branch coverage" do
    opts.should include("BranchCoverage:0:View")
  end
end

describe NCover::MethodCoverage do
  subject(:cover) { NCover::MethodCoverage.new() }
  let(:opts) { cover.get_coverage_options() }

  it "should be method coverage" do
    opts.should include("MethodCoverage:0:View")
  end
end

describe NCover::SymbolCoverage do 
  subject(:cover) { NCover::SymbolCoverage.new() }
  let(:opts) { cover.get_coverage_options() }

  it "should be symbol coverage" do
    opts.should include("SymbolCoverage:0:View")
  end
end

describe NCover::CyclomaticComplexity do
  subject(:cover) { NCover::CyclomaticComplexity.new() }
  let(:opts) { cover.get_coverage_options() }

  it "should be cyclomatic complexity" do
    opts.should include("CyclomaticComplexity:100:View")
  end
end

describe NCover::AssemblyFilter do
  subject(:filter) { NCover::AssemblyFilter.new(:filter => "filter") }
  let(:opts) { filter.get_filter_options() }

  it "should be an assembly filter" do
    opts.should include("\"filter\":Assembly:false:false")
  end
end

describe NCover::ClassFilter do
  subject(:filter) { NCover::ClassFilter.new(:filter => "filter") }
  let(:opts) { filter.get_filter_options() }

  it "should be a class filter" do
    opts.should include("\"filter\":Class:false:false")
  end
end

describe NCover::DocumentFilter do
  subject(:filter) { NCover::DocumentFilter.new(:filter => "filter") }
  let(:opts) { filter.get_filter_options() }

  it "should be a document filter" do
    opts.should include("\"filter\":Document:false:false")
  end
end

describe NCover::MethodFilter do
  subject(:filter) { NCover::MethodFilter.new(:filter => "filter") }
  let(:opts) { filter.get_filter_options() }

  it "should be a method filter" do
    opts.should include("\"filter\":Method:false:false")
  end
end

describe NCover::NamespaceFilter do
  subject(:filter) { NCover::NamespaceFilter.new(:filter => "filter") }
  let(:opts) { filter.get_filter_options() }

  it "should be a namespace filter" do
    opts.should include("\"filter\":Namespace:false:false")
  end
end
