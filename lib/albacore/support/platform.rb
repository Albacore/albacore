module Albacore
  module Support
    class Platform
      def self.linux?
        RUBY_PLATFORM.include?("linux")
      end

      def self.quote(string)
        "\"#{string}\""
      end

      def self.windows_path(path)
        path.gsub("/", "\\")
      end

      def self.linux_path(path)
        path.gsub("\\", "/")
      end

      def self.format_path(path)
        quote(linux? ? linux_path(path) : windows_path(path))
      end
    end
  end
end
