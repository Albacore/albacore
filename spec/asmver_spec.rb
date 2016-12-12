require 'spec_helper'
require 'albacore/task_types/asmver'
require 'albacore/task_types/asmver/engine'
require 'albacore/task_types/asmver/file_generator'

include Albacore::Asmver

describe Albacore::Asmver::Config, 'when misconfigured' do
  subject do
    Albacore::Asmver::Config.new
  end
  it 'should throw MissingOutputError by default' do
    expect(lambda { subject.opts }).to raise_error MissingOutputError
  end
end

describe Albacore::Asmver::Config do
  subject do
    Albacore::Asmver::Config.new 'A.fs'
  end

  it 'should have a namespace that\' RW' do
    subject.namespace = 'smirk'
    subject.namespace = subject.namespace + 'smirk'
    expect(subject.namespace).to eq 'smirksmirk'
  end

  it 'can add a #using' do
    subject.out = StringIO.new
    subject.using 'System'
    expect(subject.opts.get(:usings)).to include('System')
  end
end

%w|Fs Vb Cpp Cs|.each do |lang|
  require "albacore/task_types/asmver/#{lang.downcase}"

  describe "the #{lang} engine" do
    subject do
      "Albacore::Asmver::#{lang}".split('::').inject(Object) { |o, c| o.const_get c }.new
    end

    %w|build_attribute build_named_parameters build_positional_parameters build_using_statement build_comment namespace_end namespace_start|.each do |m|
      it "should have a public API ##{m.to_s}" do
        expect(subject).to respond_to :"#{m}"
      end
    end

    describe 'when building version attribute' do
      let :version do
        subject.build_attribute 'AssemblyVersion', '0.2.3'
      end
      it 'should contain the name AssemblyVersion' do
        expect(version).to include('AssemblyVersion')
      end
      it 'should contain the version 0.2.3' do
        expect(version).to include('0.2.3')
      end
      it 'should include the "assembly:" string' do
        expect(version).to include('assembly: ')
      end
    end

    describe 'when building using statement' do
      let :using do
        subject.build_using_statement 'System.Runtime.CompilerServices'
      end
      it 'should contain the namespace System.Runtime.CompilerServices' do
        expect(using).to match(/System.{1,2}Runtime.{1,2}CompilerServices/)
      end
    end

    describe 'when building named parameters' do
      let :plist do
        subject.build_named_parameters milk_cows: true, birds_fly: false, hungry_server: 'sad server'
      end
      it 'should include the parameter names' do
        expect(plist).to match(/milk_cows .{1,2} true. birds_fly .{1,2} false. hungry_server .{1,2} "sad server"/)
      end
    end

    describe 'when building positional parameters' do
      let :plist do
        subject.build_positional_parameters ((%w|a b c hello|) << false)
      end
      it 'should include the positional parameters' do
        expect(plist).to eq('"a", "b", "c", "hello", false')
      end
    end

    describe 'when building single line comment' do
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
        expect(comment).to match(expected)
      end
    end

    describe 'when building a multi-line comment' do
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
        expect(comment).to eq(expected)
      end
    end

    describe 'when building namespace' do
      let :ns do
        subject.send :namespace_start, 'This.Ns.Here'
      end
      it 'should include the string verbatim' do
        ns =~ /This\.Ns\.Here/
      end
      let :expected do
        { 'Fs' => %r{namespace This\.Ns\.Here},
          'Vb' => %r{^$},
          'Cs' => %r{^$},
          'Cpp' => %r{namespace This::Ns::Here \{}
        }[lang]
      end
      it 'should include the correct syntax for single line comment' do
        expect(ns).to match(expected)
      end
    end
  end
end

describe FileGenerator do
  subject do FileGenerator.new(Fs.new, 'MyNamespace.Here', {}) end
  it do
    expect(subject).to respond_to(:generate)
  end
  it 'can be constructed with empty namespace' do
    FileGenerator.new(Fs.new, '', {})
  end
end

describe FileGenerator, 'when generating F# file' do
  before :all do
    @out = StringIO.new
    subject = FileGenerator.new(Fs.new, 'My.Fs.Ns', {})
    subject.generate @out,
      com_visible: false,
      assembly_title: 'My.Ns',
      assembly_version: '0.1.2',
      custom_thing: %w|a b c|,
      named_thing: { :b => 3, :c => 'hi' },
      CLSCompliant: true
  end
  let :generated do
    @out.string
  end

  it 'should include namespace' do
    expect(generated).to match /namespace My\.Fs\.Ns(\r\n?|\n)/
  end

  it 'should open System.Reflection' do
    expect(generated).to match /open System\.Reflection/
  end

  it 'should open System.Runtime.CompilerServices' do
    expect(generated).to match /open System\.Runtime\.CompilerServices/
  end

  it 'should open System.Runtime.InteropServices' do
    expect(generated).to match /open System\.Runtime\.InteropServices/
  end

  it 'should generate the ComVisible attribute' do
    expect(generated).to include('[<assembly: ComVisible(false)>]')
  end

  it 'should generate the AssemblyTitle attribute' do
    expect(generated).to include('[<assembly: AssemblyTitle("My.Ns")>]')
  end

  it 'should generate the AssemblyVersion attribute' do
    expect(generated).to include('[<assembly: AssemblyVersion("0.1.2")>]')
  end

  it 'should generate the CustomThing attribute' do
    expect(generated).to include('[<assembly: CustomThing("a", "b", "c")>]')
  end

  it 'should generate the NamedThing attribute' do
    expect(generated).to include('[<assembly: NamedThing(b = 3, c = "hi")>]')
  end

  it 'should generate the CLSCompliant attribute' do
    expect(generated).to include('[<assembly: CLSCompliant(true)>]')
  end

  it 'should end with ()\n' do
    expect(generated).to match /\(\)(\r\n?|\n)$/m
  end
end

describe FileGenerator, 'when given extra "usings"' do
  before :all do
    @out = StringIO.new
    subject = FileGenerator.new Fs.new, '', usings: ['System']
    subject.generate @out, assembly_title: 'My.Asm'
  end

  let :generated do
    @out.string
  end

  it 'should open System' do
    expect(generated).to match /open System/
  end

  it 'should open System.Reflection' do
    expect(generated).to match /open System\.Reflection/
  end

  it 'should open System.Runtime.CompilerServices' do
    expect(generated).to match /open System\.Runtime\.CompilerServices/
  end

  it 'should open System.Runtime.InteropServices' do
    expect(generated).to match /open System\.Runtime\.InteropServices/
  end

end

describe FileGenerator, 'when it should generate NO NAMESPACE' do
  before :all do
    @out = StringIO.new
    subject = FileGenerator.new(Cs.new, '', {})
    subject.generate @out,
      com_visible: false,
      assembly_title: 'My.Asm',
      assembly_version: '0.1.2',
      custom_thing: %w|a b c|,
      named_thing: { :b => 3, :c => 'hi' }
  end
  let :generated do
    @out.string
  end
  it 'should not include \'namespace\'' do
    expect(generated).to_not include('namespace')
  end
end
