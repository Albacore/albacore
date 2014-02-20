require 'albacore/task_types/test_runner'
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

describe ::Albacore::TestRunner::Cmd do
  subject do
    ::Albacore::TestRunner::Cmd.new 'work_dir', 'run-tests.exe', %w[params go here], 'lib.tests.dll'
  end
  it do
    should respond_to :execute
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
