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
end

describe ::Albacore::TestRunner::Task do
  def create_task_that_intercepts_commands opts
    task = ::Albacore::TestRunner::Task.new(config.opts)
    def task.execute_commands commands
      @commands = commands
      commands.each { |command|
        command.extend ShInterceptor
        command.execute
      }
    end

    def task.commands
      @commands
    end

    task.execute
    task
  end

  before(:context) do
    Dir.chdir 'spec'
  end

  after(:context) do
    Dir.chdir '..'
  end

  subject do
    create_task_that_intercepts_commands config.opts
  end

  context "file is in current directory" do
    let :config do
      config = ::Albacore::TestRunner::Config.new
      config.exe = 'test-runner.exe'
      config.files = 'utils_spec.rb' # not a real DLL, but we need something that exists
      config
    end

    it "should run the command from the current directory" do
      expect(subject.commands[0].invocations[0].options[:work_dir]).to eq('.')
      expect(subject.commands[0].invocations[0].executable).to eq('test-runner.exe')
    end

    it "should reference the file without directory qualifiers" do
      expect(subject.commands[0].invocations[0].parameters).to include 'utils_spec.rb'
    end
  end

  context "file is in subdirectory" do
    let :config do
      config = ::Albacore::TestRunner::Config.new
      config.exe = 'test-runner.exe'
      config.files = 'tools/fluent_migrator_spec.rb' # not a real DLL, but we need something that exists
      config
    end

    it "should run the command from the subdirectory" do
      expect(subject.commands[0].invocations[0].options[:work_dir]).to eq('tools')
      expect(subject.commands[0].invocations[0].executable).to eq('../test-runner.exe')
    end

    it "should reference the file without directory qualifiers" do
      expect(subject.commands[0].invocations[0].parameters).to include 'fluent_migrator_spec.rb'
    end
  end

  context "file is in parent directory" do
    let :config do
      config = ::Albacore::TestRunner::Config.new
      config.exe = 'test-runner.exe'
      config.files = '../Rakefile' # not a real DLL, but we need something that exists
      config
    end

    it "should run the command from the parent directory" do
      expect(subject.commands[0].invocations[0].options[:work_dir]).to eq('..')
      expect(subject.commands[0].invocations[0].executable).to eq('../spec/test-runner.exe')
    end

    it "should reference the file without directory qualifiers" do
      expect(subject.commands[0].invocations[0].parameters).to include 'Rakefile'
    end
  end
end
