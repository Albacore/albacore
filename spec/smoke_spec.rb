require 'spec_helper'
require 'logger'

# https://www.relishapp.com/rspec/rspec-core/v/2-12/docs/subject/explicit-subject
describe Array, "with some elements" do
  subject { [1,2,3] }
  it "should have the prescribed elements" do
    expect(subject).to eq [1,2,3]
  end
end

describe Enumerable, "when using #find" do
  subject do
    [OpenStruct.new(:a => "1 apple")]
  end
  it "should handle find properly one arg" do
    expect(subject.find { |f| f.a == "1 apple" }.a).to eq "1 apple"
  end
  it "should handle find properly, two args" do
    s = subject.clone
    s << OpenStruct.new(:a => "2 banana")
    expect(s.find { |f| f.a == "2 banana" }.a).to eq "2 banana"
    expect(s.find { |f| f.a == "1 banana" }).to be_nil
    expect(s.find { |f| f.a == "1 apple" }.a).to eq "1 apple" 
  end
end

describe 'logging methods' do
  class A
    include ::Albacore::Logging
    def normal str ; trace str ; end
    def blocky str ; trace { str } ; end
  end
  before do
    @logout = StringIO.new
    @app = ::Albacore::Application.new @logout, StringIO.new, StringIO.new
    @app.logger.level = Logger::DEBUG
    ::Albacore.set_application @app
  end
  subject do
    A.new
  end
  describe 'logging normally' do
    before do
      subject.normal 'my-trace-line'
      subject.blocky 'trace-is-enabled with ::DEBUG'
    end
    it 'should contain non-block line' do
      expect(@logout.string).to include('my-trace-line')
    end
    it 'should contain block line' do
      expect(@logout.string).to include('trace-is-enabled')
    end
  end
end
