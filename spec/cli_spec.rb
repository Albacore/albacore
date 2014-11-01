require 'albacore/cli'

describe Albacore::Cli do

  before :each do
    # Output to a file that doesn't conflict with the project's Rakefile file.
    @test_rake = 'Test_Rakefile'
    @test_gem = 'Test_Gemfile'
    @test_semver = 'Test_Semver'
    Albacore.stub(:rakefile).and_return @test_rake
    Albacore.stub(:gemfile).and_return @test_gem
    Albacore.stub(:semver_file).and_return @test_semver

    # Capture the output that would typically appear in the console.
    @original_stdout = $stdout
    @output = StringIO.new
    $stdout = @output
  end

  after :each do
    # Delete the Test_Rakefile if one was created.
    FileUtils.rm @test_rake
    FileUtils.rm @test_gem

    # Return output to its original value.
    $stdout = @original_stdout
  end

  %w( init initialize ).each do |command|
    describe command do
      describe 'when no Rakefile file exists' do
        it 'creates a new Rakefile and Gemfile' do
          expect {
            described_class.new [command]
          }.to change{ File.exist?(@test_rake) }.from(false).to(true)
        end
      end
      describe 'when a Rakefile file already exists' do
        before :each do
          FileUtils.touch @test_rake
          FileUtils.touch @test_gem
        end
        it 'outputs a warning message' do
          described_class.new [command]
          @output.string.should match /One of \[.*\] already exists\n/
        end
        it "does not overwrite the existing file" do
          expect {
            described_class.new [command]
          }.to_not change{ File.mtime(@test_rake) }
        end
      end
    end
  end
end
