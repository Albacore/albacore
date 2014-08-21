require 'spec_helper'

describe "pub sub" do
  it do
    @got_it = false
    Albacore.subscribe :pubsub do |obj| 
      @got_it = obj
    end
    Albacore.publish :pubsub, true
    expect(@got_it).to be true
  end

  it 'knows if it\'s Windows it\'s running on' do
    expect(::Albacore.windows? === true || ::Albacore::windows? === false).to be true
  end
  it 'should not be nil' do
    expect(::Albacore.windows?).to_not be nil
  end
end

