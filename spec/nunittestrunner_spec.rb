require 'spec_helper'
require 'albacore/nunittestrunner'

describe "nunit with paths" do
  before :all do
    @command = File.join(File.dirname(__FILE__), 'support', 'Tools', 'NUnit-v2.5', 'nunit-console-x86.exe')
    @test_assembly = File.join(File.expand_path(File.dirname(__FILE__)), 'support', 'CodeCoverage', 'nunit', 'assemblies', 'TestSolution.Tests.dll')
    @failing_test_assembly = File.join(File.expand_path(File.dirname(__FILE__)), 'support', 'CodeCoverage', 'nunit', 'failing_assemblies', 'TestSolution.FailingTests.dll')
    @output_option = "nunit-results.xml"
  end

  describe NUnitTestRunner, "the command parameters for an nunit runner" do
    before :all do
      nunit = NUnitTestRunner.new()
      nunit.command = @command
      nunit.assemblies = [@test_assembly, @failing_test_assembly]
      nunit.results_path = @output_option
      nunit.no_logo

      @command_parameters = nunit.build_parameters.join(" ")
    end

    it "should not include the path to the command" do
      @command_parameters.should_not include(@command)
    end

    it "should include the list of assemblies" do
      @command_parameters.should include("\"#{@test_assembly}\" \"#{@failing_test_assembly}\"")
    end

    it "should include the list of options" do
      @command_parameters.should include(@output_option)
    end
    
    it "should not show the logo" do 
      @command_parameters.should include("/nologo")
    end
  end

  describe NUnitTestRunner, "when configured correctly" do
    before :all do
      nunit = NUnitTestRunner.new()
      nunit.command = @command
      nunit.extend(FailPatch)
      nunit.assemblies @test_assembly
      nunit.parameters '/noshadow'
      nunit.no_logo
      nunit.execute
    end

    it "should execute" do
      $task_failed.should be_false
    end
  end
end
