# encoding: utf-8

require 'spec_helper'
require 'albacore'
require 'albacore/nugets'

describe "when trying to find nuget exe in gem" do
  subject do
    Albacore::Nugets::find_nuget_gem_exe
  end

  it "should return path to the correct executable" do
    expect(subject).to end_with('nuget.exe')
  end

  it "the path should point to something" do
    expect(File.exists?( subject)).to be true
  end
end
