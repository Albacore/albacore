require 'albacore/tools'

describe 'when calling Tools#git_release_notes' do
  subject do
    Albacore::Tools.git_release_notes
  end
  it 'should start with "Release Notes"...' do
    expect(subject).to match /Release Notes for /
  end
end

