require 'spec_helper'
require 'albacore/albacoretask'
require 'system_patch'

class RunCommandObject
  include Albacore::Task
  include Albacore::RunCommand

  def execute
    result = run_command "Run Command Test Object"
  end
end

shared_context 'mocked system' do
  subject { RunCommandObject.new 'test.exe' }
  before(:all) { subject.extend SystemPatch }
end

describe "the most simplistic call to run_command" do
  include_context 'mocked system'
  before(:all) { subject.execute }
  it("should quote the cmd") { subject.system_command.should eq(%{"test.exe"}) }
end

describe "when specifying a parameter to a command" do
  include_context 'mocked system'
  before :all do
    subject.parameters "param1"
    subject.execute
  end
  it "should separate the parameters from the command" do
    subject.system_command.should eq(%{"test.exe" param1})
  end
end

describe "when specifying multiple parameters to a command" do

  include_context 'mocked system'

  before :all do
    subject.parameters "param1", "param2", "param3"
    subject.execute
  end

  it "should separate all parameters by a space" do
    subject.system_command.should eq(%{"test.exe" param1 param2 param3})
  end
end

describe "when executing a runcommand object twice" do

  include_context 'mocked system'

  before :all do
    subject.parameters "1", "2", "3"
    subject.execute
    subject.execute
  end

  it "should only pass the parameters to the command once for the first execution" do
    subject.system_command.should eq(%{"test.exe" 1 2 3})
  end

  it "should only pass the parameters to the command once for the second execution" do
    subject.system_command.should eq(%{"test.exe" 1 2 3})
  end
end

describe "when the command exists relative to the project root" do
  include_context 'mocked system'

  before :all do
    File.open('test.exe', 'w+') do |f|
      f.puts ' '
    end
    subject.execute
  end

  after :all do
    FileUtils.rm_f('test.exe')
  end

  it "should expand the path" do
    subject.system_command.should == "\"#{File.expand_path('test.exe')}\""
  end
end
