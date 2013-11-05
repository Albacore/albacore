require 'albacore/task_types/asmver'

describe ::Albacore::Asmver::Config, 'when setting attributes and out' do
  let :strio do
    StringIO.new
  end
  subject do
    ::Albacore::Asmver::Config.new
  end
  def task
    @task
  end
  before :each do
    subject.file_path = 'Version.fs'
    subject.namespace = 'Hello.World'
    subject.attributes guid: 'b766f4f3-3f4e-49d0-a451-9c152059ae81',
      assembly_version: '0.1.2'
    subject.out = strio
    @task = ::Albacore::Asmver::Task.new(subject.opts)
    @task.execute
  end
  it 'should write namespace' do
    strio.string.should include('namespace Hello.World')
  end
  it 'should write Guid("...")' do
    strio.string.should include('[<assembly: Guid("b766f4f3-3f4e-49d0-a451-9c152059ae81")>]')
  end
  it 'should write AssemblyVersion' do
    strio.string.should include('[<assembly: AssemblyVersion("0.1.2")>]')
  end
end

