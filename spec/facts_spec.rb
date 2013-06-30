require 'spec_helper'
require 'albacore/facts'

describe Albacore::Facts, "when querying processor info" do
  subject { Albacore::Facts.processor_count }
  it { should be > 0 }
end
