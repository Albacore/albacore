require 'albacore/task_types/test_runner'
require 'support/sh_interceptor'
require 'map'

describe ::Albacore::TestRunner::Config do
  it do
    should respond_to :opts
  end
  it do
    should respond_to :files=
  end
  it do
    should_not respond_to :files
  end
  it do
    should respond_to :copy_local
  end
  it do
    should respond_to :exe=
  end
end
describe ::Albacore::TestRunner::Config do
  subject do
    ::Albacore::TestRunner::Config.new
  end

  before :each do
    subject.add_parameter '/TestResults=/b/c/d/e.xml'
  end

  it 'should have the appropriate parameter in #opts.get(:parameters)' do
    subject.opts.get(:parameters).should include('/TestResults=/b/c/d/e.xml')
  end
end

describe 'the order of which parameters are passed', ::Albacore::TestRunner::Config do
  subject do
    cmd = ::Albacore::TestRunner::Config.new
    cmd.files = 'file.dll'
    cmd.exe   = 'test-runner.exe'
    cmd.add_parameter '/TestResults=abc.xml'
    cmd
  end

  let :params do
    subject.opts.get(:parameters)
  end

  it 'should first pass the flags' do
    params.first.should eq('/TestResults=abc.xml')
  end

  it 'should pass the file as a :files' do
    subject.opts.get(:files).should eq(['file.dll'])
  end
end

describe ::Albacore::TestRunner::Cmd do
  subject do
    cmd = ::Albacore::TestRunner::Cmd.new 'work_dir', 'run-tests.exe', %w[params go here], 'lib.tests.dll'
    cmd.extend ShInterceptor
    cmd
  end

  it do
    should respond_to :execute
  end

  it 'should include the parameters when executing' do
    subject.execute

    # the intersection of actual parameters with expected should eq expected
    (subject.parameters - (subject.parameters - %w|params go here|)).
      should eq(%w|params go here|)
  end
end

describe ::Albacore::TestRunner::Task do
  subject do
    ::Albacore::TestRunner::Task.new Map.new
  end
  it do
    should respond_to :execute
  end
end
