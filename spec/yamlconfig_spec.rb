require "spec_helper"

class Test
  include Albacore::Task

  attr_accessor :foo,
                :bar,
                :baz
end

describe "yaml configuration" do
  subject(:yml) { Test.new() }

  before :each do  
    yml.configure("spec/yaml/test.yml")
  end
  
  it "should set the property" do
    yml.foo.should == "foo"
  end
      
  it "should set the hashtable" do
    yml.bar["foo"].should == "foo"
    yml.bar["bar"].should == "bar"
  end
  
  it "should set a symbol value" do
    yml.baz.should == :baz
  end  
end

describe "yaml configuration by folder" do
  Albacore.configure.yaml_config_folder = "spec/yaml"

  subject(:yml) { Test.new() }

  before :each do
    yml.load_config_by_task_name("test")
  end
  
  it "should set the property" do
    yml.foo.should == "foo"
  end
      
  it "should set the hashtable" do
    yml.bar["foo"].should == "foo"
    yml.bar["bar"].should == "bar"
  end
  
  it "should set a symbol value" do
    yml.baz.should == :baz
  end  
end
