require 'albacore/paths'
require 'albacore/rake_overrides'

describe 'when overriding rake' do
  it 'has string return value by default' do
    expect(::Rake.old_original_dir).to be_an_instance_of String
  end

  it 'should override Rake#original_dir so that includes separator chars' do
    # assume we never test from root of file system:
    expect(::Rake.original_dir).to include(Paths.separator)
  end

  it 'should have #original_dir_path' do
    expect(::Rake).to respond_to(:original_dir_path)
  end

  it 'should have #original_dir_path().to_s include the separator' do
    expect(::Rake.original_dir_path.to_s).to include(Paths.separator)
  end
end
