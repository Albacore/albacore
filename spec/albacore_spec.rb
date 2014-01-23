require 'spec_helper'

describe "pub sub" do
  it do
    @got_it = false
    Albacore.subscribe :pubsub do |obj| 
      @got_it = obj
    end
    Albacore.publish :pubsub, true
    @got_it.should be_true
  end

  it 'knows if it\'s Windows it\'s running on' do
    (::Albacore.windows? === true || ::Albacore::windows? === false).should be_true
  end
  it 'should not be nil' do
    ::Albacore.windows?.should_not be_nil
  end
end

