require 'albacore/albacoretask'
require 'zip'
require 'zip/filesystem'
include Zip

class Unzip
  include Albacore::Task
  
  attr_reader   :force
  
  attr_accessor :destination, 
                :file

  def initialize
    super()
    update_attributes(Albacore.configuration.unzip.to_hash)
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
        File.delete(path) if @force and File.file?(path)
        
        zip.extract(file, path) unless File.exist?(path)
      end
    end
  end
  
  def force
    @force = true
  end
end
