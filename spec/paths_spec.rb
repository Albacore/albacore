require 'albacore/paths'

describe ::Albacore::Paths.method(:join_str), 'when joining path segments' do
  it 'id' do
    subject.call('.').should eq('.')
  end

  it 'id slash' do
    subject.call('.', '/').should eq(Paths.separator)
  end

  it 'id slash win' do
    subject.call('.', '\\').should eq(Paths.separator)
  end

  it 'id slash with root' do
    subject.call('.', '/', '/b').should eq(Paths.separator + 'b')
  end

  it 'id slash with root win' do
    subject.call('.', '\\', '\\b').should eq(Paths.separator + 'b')
  end

  it 'id double slash' do
    subject.call('.', 'b/', 'c/').should eq('b' + Paths.separator + 'c' + Paths.separator)
  end

  it 'id double slash win' do
    subject.call('.', 'b\\', 'c\\').should eq('b' + Paths.separator + 'c' + Paths.separator)
  end
end

