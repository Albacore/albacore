require 'albacore/dsl'
require 'spec_helper'

describe "what methods are included by default" do
  require 'albacore'
  class A ; include Albacore::DSL ; end
  subject { A.new.method(:sh).to_s }
  it { should include("Albacore::CrossPlatformCmd") } 
end

class X
  include Albacore::DSL
end

#puts "X has methods: #{X.new.private_methods.inspect}"

%w[nugets_restore nugets_pack asmver build].each do |sym|
  method = :"#{sym}"
  describe "that #{method}(*args, &block) is included when doing `require 'albacore'`" do
    subject do
      X.new
    end
    it do
      expect(subject.method(method)).to_not be nil
    end
  end
end

describe 'calling dsl method without symbol name' do
  subject do
    x = X.new
    # calling the #build method in the dsl without any name should name it
    x.method(:build).call do |b|
    end
  end
  it 'should be named "build"' do
    expect(subject.name).to eq('build')
  end
end
