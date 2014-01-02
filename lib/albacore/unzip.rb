require "albacore/albacoretask"
require "albacore/config/unzipconfig"
require "zip"
require "zip/filesystem"

class Unzip
  include Albacore::Task
  include Configuration::Unzip
  
  attr_reader   :force
  
  attr_accessor :destination, 
                :file

  def initialize
    super()
    update_attributes(unzip.to_hash)
  end
    
  def execute()
    unless @file
      fail_with_message("unzip requires #file")
      return
    end
  
    Zip::File.open(@file) do |zip|
      zip.each do |file|
        path = File.join(@destination, file.name)
        dir = File.dirname(path)
        
        FileUtils.mkdir_p(dir)
        File.delete(path) if (@force && File.file?(path))
        
        zip.extract(file, path) unless File.exist?(path)
      end
    end
  end
  
  def force
    @force = true
  end
end
