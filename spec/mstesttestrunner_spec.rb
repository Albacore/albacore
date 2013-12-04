require 'spec_helper'
require 'albacore/mstesttestrunner'

shared_context "mstest paths" do
  before :all do
    @command = File.join(File.dirname(__FILE__), 'support', 'Tools', 'MSTest-2010', 'mstest.exe')
    @assembly = File.join(File.expand_path(File.dirname(__FILE__)), 'support', 'CodeCoverage', 'mstest', 'TestSolution.MSTestTests.NET40.dll')
  end
end

describe MSTestTestRunner, "the command parameters for an mstest runner" do
  include_context "mstest paths"

  before :all do
    mstest = MSTestTestRunner.new()
    mstest.command = @command
    mstest.assemblies @assembly
    mstest.tests 'APassingTest', 'AFailingTest'
    
    @result = mstest.build_parameters.join(" ")
  end
    
  it "should not include the path to the command" do
    @result.should_not include(@command)
  end
  
  it "should include the list of assemblies" do
    @result.should include("/testcontainer:\"#{@assembly}\"")
  end

  it "should include the specific set of tests" do
    @result.should include("/test:APassingTest /test:AFailingTest")
  end
end

describe MSTestTestRunner, "when configured correctly" do
  include_context "mstest paths"

  before :all do
    mstest = MSTestTestRunner.new()
    mstest.command = @command
    mstest.extend(FailPatch)
    mstest.assemblies @assembly
    mstest.log_level = :verbose
    mstest.parameters "/noisolation", "/noresults"
    mstest.tests "APassingTest"
    mstest.no_logo
    mstest.execute
  end
  
  it "should execute" do
    $task_failed.should be_false
  end
end

describe MSTestTestRunner, "when configured correctly, but a test fails" do
  include_context "mstest paths"

  before :all do
    mstest = MSTestTestRunner.new()
    mstest.command = @command
    mstest.extend(FailPatch)
    mstest.assemblies @assembly
    mstest.log_level = :verbose
    mstest.parameters "/noisolation", "/noresults"
    mstest.tests "AFailingTest"
    mstest.no_logo
    mstest.execute
  end

  it "should fail" do
    $task_failed.should be_true
  end
end
  