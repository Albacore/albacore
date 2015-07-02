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
  it do
    should respond_to :native_exe
  end
end
describe ::Albacore::TestRunner::Config do
  subject do
    ::Albacore::TestRunner::Config.new
  end

  before :each do
    subject.add_parameter '/TestResults=/b/c/d/e.xml'
    subject.native_exe
  end

  it 'should have the appropriate parameter in #opts.get(:parameters)' do
    expect(subject.opts.get(:parameters)).to include('/TestResults=/b/c/d/e.xml')
  end
  
  it 'should have clr_command=false' do
    expect(subject.opts.get(:clr_command)).to be false
  end
end

describe 'the order of which parameters are passed', ::Albacore::TestRunner::Config do
  subject do
    config = ::Albacore::TestRunner::Config.new
    config.files = 'a/b/c/file.dll'
    config.exe   = 'test-runner.exe'
    config.add_parameter '/TestResults=abc.xml'
    config
  end

  let :params do
    subject.opts.get(:parameters)
  end

  it 'should first pass the flags' do
    expect(params.first).to eq('/TestResults=abc.xml')
  end

  it 'should pass the file as a :files' do
    expect(subject.opts.get(:files)).to eq(['a/b/c/file.dll'])
  end
end

describe ::Albacore::TestRunner::Cmd do
  subject do
    cmd = ::Albacore::TestRunner::Cmd.new 'work_dir', 'run-tests.exe', %w[params go here], 'a/b/c/lib.tests.dll'
    cmd.extend ShInterceptor
    cmd.execute
    cmd
  end

  it 'should include the parameters when executing' do
    # the intersection of actual parameters with expected should eq expected
    expect(subject.parameters - (subject.parameters - %w|params go here|)).
      to eq(%w|params go here|)
  end

  it 'should give the full path when executing' do
    expect((subject.parameters - %w|params go here|)).to eq(%w|a/b/c/lib.tests.dll|)
  end
end

describe ::Albacore::TestRunner::Task do
  let :config do
    config = ::Albacore::TestRunner::Config.new
    config.files = 'a/b/c/file.dll'
    config.exe   = 'test-runner.exe'
    config.add_parameter '/TestResults=abc.xml'
    config
  end

  subject do
    ::Albacore::TestRunner::Task.new(config.opts)
  end

  it do
    should respond_to :execute
  end

  def test_dir_exe hash
    given = hash.first[0]
    expected = hash.first[1]
    subject.send(:handle_directory, given[0], given[1]) do |dir, exe|
      expect(dir).to eq(expected[0])
      expect(exe).to eq(expected[1])
    end

  end

  it 'should handle relative handle_directory' do
    test_dir_exe ['d.dll', 'e.exe'] => ['.', 'e.exe']
  end

  it 'should handle actual relative directories correctly' do
    test_dir_exe ['a/d.dll', 'e.exe'] => ['a', '../e.exe']
  end

  it 'should handle negative dirs by getting current dir name' do
    subject.send(:handle_directory, '../d.dll', 'e.exe') do |dir, exe|
      expect(dir).to eq('..')
      # at this point, the exe file is just a dir in
      expect(exe).to match /\w+\/e\.exe/
    end
  end
end
