require 'albacore/paths'

describe Paths.method(:join), 'when joining path segments' do
  let :s do
    Paths.separator
  end

  let :sample do
    subject.call(*%w|a b c|)
  end

  let :abc do
    'a' + s + 'b' + s + 'c'
  end

  it 'should return id' do
    expect(subject.call('abc').to_s).to eq('abc')
  end 

  it 'should return with proper separator' do
    expect(sample.to_s).to eq('a' + s + 'b' + s + 'c')
  end

  it 'should be joinable' do
    expect(sample.join('d').to_s).to include(s)
  end

  it 'should be +-able' do
    expect((sample + 'd').to_s).to include(s)
  end

  it 'can join with *' do
    expect(subject.call('a').join('*/').to_s).to eq('a' + s + '*' + s)
  end

  it 'accepts multiple paths' do
    expect(subject.call('a', 'b', 'c').to_s).to eq(abc)
  end

  it 'returns something accepting multiple paths' do
    expect(subject.call('a', 'b', 'c').join('d', 'e').to_s).to eq(abc + s + 'd' + s + 'e')
  end

  it 'should be presentable in "unix" style' do
    expect(sample.as_unix.to_s).to_not include('\\')
  end

  it 'should handle joining on a type like itself' do
    expect(sample.join(sample).to_s).to eq(abc + s + abc)
    sample.join(sample, sample)
  end

  it 'should handle +-ing on a type like itself' do
    sample + sample
  end

  it 'should handle joining with a Pathname' do
    pending "don't know why not working" if Albacore.windows?
    expect((sample.join Pathname.new('x'))).to eq(Paths::PathnameWrap.new(abc + s + 'x'))
  end

  it 'should handle +-ing with a Pathname' do
    pending "don't know why not working" if Albacore.windows?
    expect((sample + Pathname.new('x'))).to eq(Paths::PathnameWrap.new(abc + s + 'x'))
  end

  it do
    expect(sample).to respond_to(:hash)
  end

  it do
    expect(sample).to respond_to(:eql?)
  end
  
  it 'joins with identity' do
    expect(subject.call(Paths::PathnameWrap.new(abc)).to_s).to eq(abc)
  end

  it 'joins with others' do
    expect(sample.join(Paths::PathnameWrap.new(abc)).to_s).to eq(abc + s + abc)
  end
end

describe Paths.method(:join_str), 'when joining path segments' do
  let :s do
    Paths.separator
  end

  it 'id' do
    expect(subject.call('.')).to eq('.')
  end

  it 'id slash' do
    expect(subject.call('.', '/')).to eq(s)
  end

  it 'id slash win' do
    expect(subject.call('.', '\\')).to eq(s)
  end

  it 'id slash with root' do
    expect(subject.call('.', '/', '/b')).to eq(s + 'b')
  end

  it 'id slash with root win' do
    expect(subject.call('.', '\\', '\\b')).to eq(s + 'b')
  end

  it 'id double slash' do
    expect(subject.call('.', 'b/', 'c/')).to eq('b' + s + 'c' + s)
  end

  it 'id double slash win' do
    expect(subject.call('.', 'b\\', 'c\\')).to eq('b' + s + 'c' + s)
  end
end

