require "spec_helper"
require "albacore/mspectestrunner"

describe MSpecTestRunner, "when providing all the great parameters" do
  let(:mspec) do
    mspec = MSpecTestRunner.new
    mspec.command = "path/to/mspec.exe"
    mspec.assemblies = ["a.dll", "b.dll"]
    mspec.html_output = "output.html"
    mspec
  end

  let(:parameters) do 
    mspec.build_parameters.join(" ")
  end

  it "should use the command" do
    mspec.command.should == "path/to/mspec.exe"
  end
  
  it "should have two assemblies" do
    parameters.should include("\"a.dll\"")
    parameters.should include("\"b.dll\"")
  end
  
  it "should have an html switch and path" do
    parameters.should include("--html \"output.html\"")
  end
end
