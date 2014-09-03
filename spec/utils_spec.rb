require 'map'

describe 'getting defaults from map' do
  subject do
    Map.options my_key: 456, dir: 'abc'
  end
  it 'should contain :my_key' do
    expect(subject.getopt :my_key).to be 456
  end
  it 'should contain :my_key with #get' do
    expect(subject.get :my_key).to be 456
  end
  it 'should allow defaults' do
    expect(subject.getopt(:doesntexist, 333)).to be 333
  end
end
