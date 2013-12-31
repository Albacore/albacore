require "spec_helper"
require "albacore/ncoverconsole"
require "albacore/nunittestrunner"

describe NCoverConsole do
  let(:runner) do
    runner = NUnit.new()
    runner.command = "nunit"
    runner.assemblies = ["a.dll"]
    runner.parameters = ["/nologo"]
    runner
  end

  subject(:task) do
    task = NCoverConsole.new()
    task.extend(SystemPatch)
    task.extend(FailPatch)
    task.command = "ncover"
    task.include_assemblies = ["a.dll", "b.dll"]
    task.exclude_assemblies = ["c.dll"]
    task.include_attributes = ["foo", "bar"]
    task.exclude_attributes = ["baz"]
    task.coverage = [:branch, :symbol]
    task.output = {:xml => "coverage.xml"}
    task.test_runner = runner
    task
  end

  let(:cmd) { task.system_command }

  context "when using defaults" do
    before :each do
      task.execute
    end

    it "should use the command" do
      cmd.should include("ncover")
    end

    it "should include these assemblies" do
      cmd.should include("//include-assemblies \"a.dll;b.dll\"")
    end

    it "should exclude these assemblies" do
      cmd.should include("//exclude-assemblies \"c.dll\"")
    end

    it "should include these attributes" do
      cmd.should include("//include-attributes \"foo;bar\"")
    end

    it "should exclude these attributes" do
      cmd.should include("//exclude-attributes \"baz\"")
    end

    it "should cover like this" do
      cmd.should include("//coverage-type \"branch, symbol\"")
    end

    it "should output to this file" do
      cmd.should include("//xml \"coverage.xml\"")
    end

    it "should register" do
      cmd.should include("//reg")
    end

    it "should have the entire test runner command line" do
      cmd.should include("nunit \"a.dll\" /nologo")
    end
  end

  context "when overriding registration" do
    before :each do
      task.no_registration
      task.execute
    end

    it "should not register" do
      cmd.should_not include("//reg")
    end
  end
end
