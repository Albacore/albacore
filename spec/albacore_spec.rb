require 'spec_helper'

describe "pub sub" do
  it {
    @got_it = false
    Albacore.subscribe :pubsub do |obj| 
      @got_it = obj
    end
    Albacore.publish :pubsub, true
    @got_it.should be_true
  }
end
