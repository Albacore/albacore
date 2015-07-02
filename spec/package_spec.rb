require 'albacore/package'

describe ::Albacore::Package do
  subject do
    Albacore::Package.new 'NLog', 'path/to/asm.dll'
  end
  it do
    should respond_to :id
  end
  it do
    should respond_to :path
  end
  it do
    should respond_to :to_s
  end
  it 'has id' do
    expect(subject.id).to eq 'NLog'
  end 
  it 'has path' do
    expect(subject.path).to eq 'path/to/asm.dll'
  end
  it 'formats with #to_s' do
    expect(subject.to_s).to eq 'Package[path/to/asm.dll]'
  end
end
