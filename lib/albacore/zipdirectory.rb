require "albacore/albacoretask"
require "albacore/config/zipdirectoryconfig"
require "zip"

class ZipDirectory
  TaskName = :zip

  include Albacore::Task
  include Configuration::Zip
  
  attr_reader   :flatten
    
  attr_accessor :output_path
  
  attr_array    :dirs, 
                :files, 
                :exclusions

  def initialize
    @dirs = []
    @files = []
    @exclusions = []

    super()
    update_attributes(zip.to_hash)
  end
    
  def execute()
    unless @output_path
      fail_with_message("zip requires #output_path")
      return
    end

    FileUtils.rm_rf(@output_path)

    exclusions = Exclusions.new(@dirs)
    @exclusions.each { |ex| exclusions.expand!(ex) }
    
    archive = Archive.new(output_path, exclusions, flatten)
    @dirs.each { |path| archive.dir(path) }
    @files.each { |path| archive.file(path) }
    archive.close()
  end
  
  def flatten
    @flatten = true
  end
end

class Archive
  def initialize(archive_path, exclusions, flatten)
    @archive = Zip::File.open(archive_path, Zip::File::CREATE)
    @exclusions = exclusions
    @flatten = flatten
  end

  def dir(dir)
    pattern = File.join(dir, "**/*")
    Dir[pattern].each do |file|
      next if @exclusions.exclude?(file)

      name = @flatten ? file.sub(File.join(dir, "/"), "") : file
      @archive.add(name, file)
    end
  end

  def file(file)
    return if @exclusions.exclude?(file)

    name = @flatten ? file.split("/").last : file
    @archive.add(name, file)
  end

  def close()
    @archive.close()
  end
end

class Exclusions
  def initialize(dirs)
    @dirs = dirs
    @exclusions = []
  end

  def expand!(ex)
    if ex.is_a?(Regexp)
      @exclusions << ex 
      return
    end

    @dirs.each do |dir|
      Dir.chdir(dir) do
        matches = Dir.glob(ex)
        matches = matches.map { |path| File.join(dir, path) } unless matches[0] == ex
        @exclusions += (matches.empty? ? [ex] : matches)
      end
    end
  end

  def exclude?(path)
    @exclusions.any? do |ex|
      return path =~ ex if ex.is_a?(Regexp)
      return path == ex
    end
  end
end
