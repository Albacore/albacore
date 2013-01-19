require 'spec_helper'
require 'albacore/config/netversion'

class NetVersionTest
  include Configuration::NetVersion
end

describe :NetVersion, 'when getting the win_dir' do
  before do
    @subject = NetVersionTest.new
    @win_dir = @subject.win_dir
  end
  
  it 'should be in the system path' do
    @win_dir.upcase.should eq 'C:\\WINDOWS'
  end
end

describe :NetVersion, 'when getting the net version' do
  before do
    @subject = NetVersionTest.new
  end
  
  it 'should have v2.0' do
    @subject.get_net_version(:net2).should include 'v2.0'
  end
  
  it 'should have v3.0' do
    @subject.get_net_version(:net3).should include 'v2.0'
  end
  
  it 'should have v3.5' do
    @subject.get_net_version(:net35).should include 'v3.5'
  end
  
  it 'should have v4.0' do
    @subject.get_net_version(:net4).should include 'v4.0'
  end
  
  it 'should have v4.5' do
    @subject.get_net_version(:net45).should include 'v4.0'
  end
end

describe :NetVersion, 'when getting an unsupported net version' do
  before do 
    @subject = NetVersionTest.new
  end
  
  it 'should fail' do
    lambda { @subject.get_net_version :fake }.should raise_error
  end
end