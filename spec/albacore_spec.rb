describe "what methods are included by default" do
  require 'albacore'
  class A ; include Albacore::DSL ; end
  subject { A.new.method(:sh).to_s }
  it { should include("Albacore::CrossPlatformCmd") } 
end
