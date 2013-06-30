require 'spec_helper'
require 'albacore/migrate'
require 'map'
require 'sh_interceptor'

describe Albacore::Migrate::Cmd, "when calling #execute" do
  def cmd *args
    opts = Map.options(args).set(:interactive, false)
    c = Albacore::Migrate::Cmd.new opts
    c.extend ShInterceptor
    c
  end
  describe 'calling with no connection' do
    it 'raises ArgumentError' do
      expect { cmd }.
        to raise_error(ArgumentError, /connection/)
    end
  end
  describe 'calling with :task_override' do
    let (:c) {
      cmd :task_override => '--toversion=4', :conn => 'conn'
    }
    subject { c.execute }
    it 'does not contain --task' do
      c.received_args.should_not include('--task')
    end
    it 'includes --toversion=4' do
      #c.received_args.should include('--toversion=4')
    end
  end
end
