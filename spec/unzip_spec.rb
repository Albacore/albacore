require 'spec_helper'
require 'albacore/unzip'

describe Unzip, "when providing configuration" do
  let :uz do
    Albacore.configure do |config|
      config.unzip.file = "configured"
      config.unzip.force = true
    end
    uz = Unzip.new
  end

  it "should use the configured values" do
    uz.file.should == "configured"
    uz.force.should be_true
  end
end
