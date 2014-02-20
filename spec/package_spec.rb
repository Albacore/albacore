require 'albacore/package'

describe ::Albacore::Package do
  subject do
    Package.new 'NLog', 'path/to/asm.dll'
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
    subject.id.should eq 'NLog'
  end 
  it 'has path' do
    subject.path.should eq 'path/to/asm.dll'
  end
  it 'formats with #to_s' do
    subject.to_s.should eq 'Package[path/to/asm.dll]'
  end
end
