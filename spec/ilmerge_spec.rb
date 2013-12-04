require 'spec_helper'
require 'albacore/ilmerge'

describe IlMerge do
  before :each do
    @me = IlMerge.new
    @me.output = 'output.dll'
  end

  context 'when #command is not set but is installed' do 
    before :each do
      @expected_path = "C:/Program Files (x86)/Microsoft/ILMerge/ilmerge.exe"
      File.should_receive(:exists?).with(@expected_path).and_return(true)
    end
    
    it "finds the installed program path" do
      @me.default_command.should == @expected_path
    end
  end
  
  context 'when #command is set manually' do
    before :each do
      @me.command = "ilmerge"
    end
    
    it "uses the manual value" do
      @me.command.should == "ilmerge"
    end
  end

  context 'when #assemblies is never set' do
    it "raises an ArgumentError" do
      expect { @me.build_parameters }.to raise_error(RuntimeError)
    end
  end

  context 'when setting #assemblies' do
    before :each do 
      @me.assemblies = ['assy_1.dll', 'assy_2.dll']
    end
  
    it "has parameters that contains all assemblies listed" do
      @me.build_parameters.flatten.should == %w{/out:"output.dll" assy_1.dll assy_2.dll}
    end
  end
end
