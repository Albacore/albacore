require 'albacore/paths'

describe ::Albacore::Paths.method(:join), 'when joining path segments' do
  let :sample do
    subject.call(*%w|a b c|)
  end

  it 'should return id' do
    subject.call('abc').to_s.should eq('abc')
  end 

  it 'should return with proper separator' do
    sample.to_s.should eq('a' + Paths.separator + 'b' + Paths.separator + 'c')
  end

  it 'should be joinable' do
    sample.join('d').to_s.should include(Paths.separator)
  end

  it 'should be +-able' do
    (sample + 'd').to_s.should include(Paths.separator)
  end
end

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

