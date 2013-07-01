require 'spec_helper'
require 'albacore/migrate'
require 'map'
require 'sh_interceptor'

describe Albacore::Migrate::MigrateCmdFactory, "when constructing" do
  subject { Albacore::Migrate::MigrateCmdFactory.create :interactive => false, :conn => 'c'}
  it { should_not be_nil }

  describe 'with :file context' do
    it 'raises error about file' do
      expect { Albacore::Migrate::MigrateCmdFactory.create :file => 'migrate_these.txt', :interactive => false, :conn => 'c' }.
        to raise_error(ArgumentError, /not find/)
    end
  end
end

describe Albacore::Migrate::Cmd, "when calling #execute" do

  def cmd *args
    opts = Map.options(args).apply({
        :interactive => false,
        :conn => 'connection-string'
      })
    @logger.debug "calling new with #{opts.inspect}"
    c = Albacore::Migrate::Cmd.new opts
    c.extend ShInterceptor
    c
  end

  # requires a let(:c)
  shared_context 'executing command' do
    subject { c.execute ; c.received_args[1] }
  end

  describe 'calling with no connection' do
    it 'raises ArgumentError' do
      expect { Albacore::Migrate::Cmd.new :interactive => false }.
        to raise_error(ArgumentError, /connection/)
    end
  end

  describe 'calling with no dll' do
    it 'raises ArgumentError' do
      expect { Albacore::Migrate::Cmd.new :interactive => false,
        :dll => '',
        :conn => 'abc' }.
        to raise_error(ArgumentError, /dll/)
    end
  end

  describe 'when given :task_override' do
    let (:c) { cmd :task_override => '--toversion=4' }
    include_context 'executing command'
    it 'does not contain --task' do
      subject.should_not include('--task')
    end
    it 'includes --toversion=4' do
      subject.should include('--toversion=4')
    end
  end

  describe 'when given extras' do
    let (:extras) { [ '--a', '--b' ] }
    let (:c) { cmd :extras => extras }
    include_context 'executing command'
    it 'should contain extras' do
      extras.
        each { |e| subject.should include(e) }
    end
  end

  describe 'when given :direction' do
    let (:task) { 'migrate:down' }
    let (:c) { cmd :direction => "migrate:down" }
    include_context 'executing command'
    it { should include('migrate:down') }
  end

end
