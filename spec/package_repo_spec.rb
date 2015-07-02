require 'albacore/package_repo'

describe ::Albacore::PackageRepo do
  subject do
    Albacore::PackageRepo.new '.'
  end
  it 'can find latest amongst a number of packages in the repo' do
    is_expected.to respond_to(:find_latest)
  end
end
