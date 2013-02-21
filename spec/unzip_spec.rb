require 'spec_helper'
require 'albacore/unzip'

describe Unzip, "when providing configuration" do
  let :uz do
    Albacore.configure do |config|
      config.unzip.file = "configured"
    end
    uz = Unzip.new
  end

  it "should use the configured values" do
    uz.file.should == "configured"
  end

  it "should not 'force' by default" do
    uz.instance_variable_get(:@force).should be_nil
  end
  
  it "should enable 'force' by calling the force() method" do
    uz.force
    uz.instance_variable_get(:@force).should be_true
  end
end

describe Unzip, "when executing the task" do
  let :uz do
    zipped_file = mock('foo.txt')
    zipped_file.stub(:name).and_return('foo.txt')

    zip_file = mock('foo.zip')
    zip_file.stub(:each).and_yield(zipped_file)
    zip_file.stub(:extract)

    Zip::ZipFile.stub!(:open).and_yield(zip_file)
    FileUtils.stub(:mkdir_p)
    File.stub!(:file?).and_return(true)

    uz = Unzip.new
    uz.file = 'foo.zip'
    uz.destination = '/tmp'
    uz
  end

  it "should delete the destinationfile if forced" do
    File.should_receive(:delete).with('/tmp/foo.txt')

    uz.force
    uz.execute
  end

  it "should keep the destination file if not forced" do
    File.should_not_receive(:delete)

    uz.execute
  end
end
