require 'albacore/paths'
require 'albacore/rake_overrides'

describe 'when overriding rake' do
  it 'has string return value by default' do
    ::Rake.old_original_dir.should be_an_instance_of String
  end

  it 'should override Rake#original_dir so that includes separator chars' do
    # assume we never test from root of file system:
    ::Rake.original_dir.should include(Paths.separator)
  end

  it 'should have #original_dir_path' do
    ::Rake.should respond_to(:original_dir_path)
  end

  it 'should have #original_dir_path().to_s include the separator' do
    ::Rake.original_dir_path.to_s.should include(Paths.separator)
  end
end
