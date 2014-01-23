require 'albacore/paths'
require 'albacore/albacore_module'

module ::Rake
  class << self
    alias_method :old_original_dir, :original_dir

    # get the original dir that rake was called from as a string
    def albacore_original_dir *args
      ::Albacore::Paths::PathnameWrap.new(old_original_dir(*args)).to_s
    end

    alias_method :original_dir, :albacore_original_dir

    # get the original dir that rake was called from a Pathname
    def original_dir_path
      ::Albacore::Paths::PathnameWrap.new(old_original_dir())
    end
  end
end

