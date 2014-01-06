require "spec_helper"

describe Albacore::Support::Platform do
  it "should quote strings" do
    Albacore::Support::Platform.quote("test").should eq("\"test\"")
  end

  it "should double-backslash Windows paths" do
    Albacore::Support::Platform.windows_path("a/windows/path").should eq("a\\windows\\path")
  end

  it "should single-forwardslash Linux paths" do
    Albacore::Support::Platform.linux_path("a\\linux\\path").should eq("a/linux/path")
  end
end
