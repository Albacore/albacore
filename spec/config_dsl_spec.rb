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
    expect(subject.in).to eq(expected)
  end
  it 'should have remapped :out' do
    expect(subject.out).to eq(expected)
  end
  it 'should be able to read and write :a' do
    expect(subject.a).to eq(expected)
  end
  it 'should be able to read and write :b' do
    expect(subject.b).to eq(expected)
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
    expect(subject.x).to eq(expected)
  end
  it 'should have called x block' do
    expect(subject.was_called).to eq(expected)
  end
  it 'should have called y block' do
    expect(subject.y_called).to eq(expected)
  end
end
