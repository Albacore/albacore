require 'albacore/task_types/asmver/engine'
require 'albacore/task_types/asmver/cs'

describe 'Engine for generating assembly version info files' do
end

%w|Fs Vb Cpp Cs|.each do |lang|
  require "albacore/task_types/asmver/#{lang}"
  describe "the #{lang} engine" do
    subject do
      "Albacore::Asmver::#{lang}".split('::').inject(Object) { |o, c| o.const_get c }.new
    end
    %w|build_attribute build_named_parameters build_positional_parameters build_using_statement build_comment|.each do |m|
      it do
        should respond_to(:"#{m}")
      end
    end
    describe 'building version attribute' do
      let :version do
        subject.build_attribute 'AssemblyVersion', '0.2.3'
      end
      it 'should contain the name' do
        version.should include('AssemblyVersion')
      end
      it 'should contain the version' do
        version.should include('0.2.3')
      end
      it 'should include the "assembly:" string' do
        version.should include('assembly: ')
      end
    end
    describe 'building using statement' do
      let :using do
        subject.build_using_statement 'System.Runtime.CompilerServices'
      end
      it 'should contain the namespace' do
        using.should =~ /System.{1,2}Runtime.{1,2}CompilerServices/
      end
    end
    describe 'building named parameters' do
      let :plist do
        subject.build_named_parameters milk_cows: true, birds_fly: false, hungry_server: '"sad server"'
      end
      it 'should include the parameter names' do
        plist.should =~ /milk_cows .{1,2} true. birds_fly .{1,2} false. hungry_server .{1,2} "sad server"/
      end
    end
    describe 'building positional parameters' do
      let :plist do
        subject.build_positional_parameters ((%w|a b c hello|) << false)
      end
      it 'should include the positional parameters' do
        plist.should =~ /a. b. c. hello. false/
      end
    end
    describe 'building single line comment' do
      let :comment do
        subject.build_comment 'this is my comment'
      end
      it 'should include the string verbatim' do
        comment =~ /this is my comment/
      end
      let :expected do
        { 'Fs' => %r{// this is my comment},
          'Vb' => %r{' this is my comment},
          'Cs' => %r{// this is my comment},
          'Cpp' => %r{// this is my comment}
        }[lang]
      end
      it 'should include the correct syntax for single line comment' do
        comment.should =~ expected
      end
    end
    describe 'building a multi-line comment' do
      let :comment do
        subject.build_comment %{This is a very interesting comment
on many lines}
      end
      let :expected do
        { 'Cs' => %{/*
 This is a very interesting comment
 on many lines
*/},
          'Fs' => %{(*
 This is a very interesting comment
 on many lines
*)},
          'Vb' =>
%{' This is a very interesting comment
' on many lines},
          'Cpp' => %{/*
 This is a very interesting comment
 on many lines
*/}
        }[lang]
      end
      it 'should build the multiline comment' do
        comment.should eq(expected)
      end
    end
  end
end
