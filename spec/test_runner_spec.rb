require 'albacore/task_types/test_runner'
require 'support/sh_interceptor'
require 'map'

describe ::Albacore::TestRunner::Config do
  it do
    should_not respond_to :files
  end
  it do
    should respond_to :copy_local
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

  context "native_exe not specified" do
    let :config do
      config = ::Albacore::TestRunner::Config.new
      config.exe = 'test-runner.exe'
      config.files = 'utils_spec.rb' # not a real DLL, but we need something that exists
      config
    end

    it "should execute command as CLR command" do
      subject.execute
      expect(subject.commands[0].invocations[0].options[:clr_command]).to eq(true)
    end

    it "should include the file at the beginning of the command" do
      subject.execute
      expect(subject.commands[0].invocations[0].parameters.first).to eq('utils_spec.rb')
    end
  end

  context "native_exe specified" do
    let :config do
      config = ::Albacore::TestRunner::Config.new
      config.exe = 'test-runner.exe'
      config.files = 'utils_spec.rb' # not a real DLL, but we need something that exists
      config.native_exe
      config
    end

    it "should execute command as non-CLR command" do
      subject.execute
      expect(subject.commands[0].invocations[0].options[:clr_command]).to eq(false)
    end

    it "should include the file at the beginning of the command" do
      subject.execute
      expect(subject.commands[0].invocations[0].parameters.first).to eq('utils_spec.rb')
    end
  end

  context "extra parameters and options specified" do
    let :config do
      config = ::Albacore::TestRunner::Config.new
      config.exe = 'test-runner.exe'
      config.files = 'utils_spec.rb' # not a real DLL, but we need something that exists
      config.add_parameter '/magic_parameter1'
      config.add_parameter '/magic_parameter2'
      config
    end

    it "should include the parameters at the end of the command" do
      subject.execute
      expect(subject.commands[0].invocations[0].parameters.last(2)).to eq(['/magic_parameter1', '/magic_parameter2'])
    end

    it "should include the file at the beginning of the command" do
      subject.execute
      expect(subject.commands[0].invocations[0].parameters.first).to eq('utils_spec.rb')
    end
  end

  context "file is in current directory" do
    let :config do
      config = ::Albacore::TestRunner::Config.new
      config.exe = 'test-runner.exe'
      config.files = 'utils_spec.rb' # not a real DLL, but we need something that exists
      config
    end

    it "should run the command from the current directory" do
      subject.execute
      expect(subject.commands[0].invocations[0].options[:work_dir]).to eq('.')
      expect(subject.commands[0].invocations[0].executable).to eq('test-runner.exe')
    end

    it "should reference the file without directory qualifiers" do
      subject.execute
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
      subject.execute
      expect(subject.commands[0].invocations[0].options[:work_dir]).to eq('tools')
      expect(subject.commands[0].invocations[0].executable).to eq('../test-runner.exe')
    end

    it "should reference the file without directory qualifiers" do
      subject.execute
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
      subject.execute
      expect(subject.commands[0].invocations[0].options[:work_dir]).to eq('..')
      expect(subject.commands[0].invocations[0].executable).to eq('../spec/test-runner.exe')
    end

    it "should reference the file without directory qualifiers" do
      subject.execute
      expect(subject.commands[0].invocations[0].parameters).to include 'Rakefile'
    end
  end
end
