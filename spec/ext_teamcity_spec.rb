require 'spec_helper'
require 'albacore/ext/teamcity'

describe Albacore::Ext::TeamCity, 'When outputting Teamcity progress messages' do

  def capture_stdout &block
    yield
    @output  
  end

  describe 'Simple escaping' do
    it 'Should escape [ with a pipe |' do
      Albacore::Ext::TeamCity.escape('[').should == '|['
    end
    it 'Should escape ] with a pipe |' do
      Albacore::Ext::TeamCity.escape(']').should == '|]'
    end
    it 'Should escape | with a pipe |' do
      Albacore::Ext::TeamCity.escape('|').should == '||'
    end
    it 'Should escape \' with a pipe |' do
      Albacore::Ext::TeamCity.escape('\'').should == '|\''
    end
    it 'Should escape \\n with a pipe |' do
      Albacore::Ext::TeamCity.escape("\n").should == '|n'
    end
    it 'Should escape \\r with a pipe |' do
      Albacore::Ext::TeamCity.escape("\r").should == '|r'
    end
  end

  describe 'Escaping in text block' do
    text = "Some sample text.\nDidn't need to use [ brackets ].\r\n"
    it 'Should escape the text correctly' do
      Albacore::Ext::TeamCity.escape(text).should == 'Some sample text.|nDidn|\'t need to use |[ brackets |].|r|n'
    end
  end

  describe 'When tracking nested progress blocks' do

    it 'Should progressFinish on current progress when supplying no name' do
      out = capture_stdout do
        message = 'Successfully deployed'
        Albacore.publish :start_progress, OpenStruct.new(:message => message)
        Albacore.publish :finish_progress, OpenStruct.new(:message => message)
      end
      out.string.should == "##teamcity[progressStart 'Successfully deployed']\n##teamcity[progressFinish 'Successfully deployed']\n"
    end

    it 'Should output progressFinish on parent progress then on children when supplying parent progress name' do
      parent_message = 'Deploy'
      out = capture_stdout do
        Albacore.publish :start_progress, OpenStruct.new(:message => parent_message)
        Albacore.publish :start_progress, OpenStruct.new(:message => 'child progress')
        Albacore.publish :finish_progress, OpenStruct.new(:message => parent_message)
      end
      out.string.should == "##teamcity[progressStart '#{parent_message}']\n##teamcity[progressStart 'child progress']\n##teamcity[progressFinish 'child progress']\n##teamcity[progressFinish '#{parent_message}']\n"
    end

    it 'Should output progress messages in the order they are defined' do
      parent_message = 'Deploy'
      out = capture_stdout do
        Albacore.publish :start_progress, OpenStruct.new(:message => parent_message)
        Albacore.publish :start_progress, OpenStruct.new(:message => 'child progress')
        Albacore.publish :progress, OpenStruct.new(:message => 'some progress')
        Albacore.publish :finish_progress, OpenStruct.new(:message => parent_message)
      end
      out.string.should == "##teamcity[progressStart '#{parent_message}']\n##teamcity[progressStart 'child progress']\n##teamcity[progressMessage 'some progress']\n##teamcity[progressFinish 'child progress']\n##teamcity[progressFinish '#{parent_message}']\n"
    end
  end
end
