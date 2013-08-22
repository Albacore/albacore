require 'spec_helper'
require 'rake'
require 'albacore/config_dsl'

class Example
  # self.include won't work: 'private method ...'
  self.extend ::Albacore::ConfigDSL

  attr_path :out, :in

  attr_path_accessor :a, :b

  attr_path :x do |path|
    @was_called = path
  end

  attr_path_accessor :y do |val|
    @y_called = val
  end

  def out
    @out
  end
  def in
    @in
  end

  def x
    @x
  end

  # whether the block was called
  def was_called
    @was_called
  end

  def y_called
    @y_called
  end
end

describe Example, 'when setting properties' do
  before do
    subject.out = 'a/b/c'
    subject.in  = 'a\\b\\c'
    subject.a   = 'a/b/c'
    subject.b   = 'a\\b\\c'
  end
  let :expected do
    ::Rake::Win32.windows? ? 'a\\b\\c' : 'a/b/c'
  end
  it 'should have remapped :in' do
    subject.in.should eq(expected)
  end
  it 'should have remapped :out' do
    subject.out.should eq(expected)
  end
  it 'should be able to read and write :a' do
    subject.a.should eq(expected)
  end
  it 'should be able to read and write :b' do
    subject.b.should eq(expected)
  end
end

describe Example, 'when using blocks for properties' do
  before do
    subject.x = 'a/b/c'
    subject.y = 'a\\b\\c'
  end
  let :expected do
    ::Rake::Win32.windows? ? 'a\\b\\c' : 'a/b/c'
  end
  it 'should have written x' do
    subject.x.should eq(expected)
  end
  it 'should have called x block' do
    subject.was_called.should eq(expected)
  end
  it 'should have called y block' do
    subject.y_called.should eq(expected)
  end
end
