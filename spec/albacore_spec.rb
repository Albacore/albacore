describe "what methods are included by default" do
  require 'albacore'
  class A ; include Albacore::DSL ; end
  subject { A.new.method(:sh).to_s }
  it { should include("Albacore::CrossPlatformCmd") } 
end

class X
  include Albacore::DSL
  def initialize ; end
end

puts "X has methods: #{X.new.private_methods.inspect}"

%w[nugets_restore nugets_pack asmver build test_runner restore_hint_paths].each { |sym|
  method = :"#{sym}"
  describe "that #{method}(*args, &block) is included when doing `require 'albacore'`" do
   subject { X.new }
   it { subject.respond_to?(method, true).should be_true }
  end
}
