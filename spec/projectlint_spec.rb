require 'albacore'
require 'albacore/tasks/projectlint'

describe "what methods are included by default" do
  Albacore::Tasks::ProjectLint.new :projectlint_task do |c|
  	c.project = File.expand_path('../testdata/Project.fsproj', __FILE__)
  	c.ignores = [/\.sln$/, /\.config$/,]
  end
  it("should be defined") { Rake::Task.task_defined?(:projectlint_task).should be_true }
  let(:projectlint) { Rake::Task[:projectlint_task] }
  it("should report differences") { 
	expect{ projectlint.invoke() }.to raise_error
  }
end
