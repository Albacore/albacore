require "albacore/albacoretask"
require "zip"
require "zip/filesystem"

class ZipDirectory
  TaskName = :zip
  include Albacore::Task
  
  attr_reader   :flatten
    
  attr_accessor :output_path
  
  attr_array    :dirs, 
                :files, 
                :exclusions

  def initialize
    super()
    update_attributes(Albacore.configuration.zip.to_hash)
  end
    
  def execute()
    unless @output_path
      fail_with_message("zip requires #output_path")
      return
    end
    
    clean_dirs if @dirs
    
    FileUtils.rm_rf(@output_path)
    Zip::File.open(@output_path, "w")  do |zip|
      add_directories(zip)
      add_files(zip)
    end
  end
  
  def flatten
    @flatten = true
  end
  
  # clean what, how, & why? -- explanation needed
  def clean_dirs
    @dirs.each { |dir| dir.sub!(%r[/$], "") }
  end
      
  def add_directories(zip)
    return unless @dirs

    @dirs.flatten.each do |dir|
      Dir["#{dir}/**/**"].reject{ |file| reject(file) }.each do |path|
        name = @flatten ? path.sub(dir + "/", "") : path
        zip.add(name, path)
      end
    end
  end
  
  def add_files(zip)
    return unless @files

    @files.flatten.reject{ |file| reject(file) }.each do |path|
      name = @flatten ? path.split("/").last : path
      zip.add(name, path)
    end
  end

  # I suspect the first comparison is unnecessary
  def reject(file)
    (file == @output_path) || excluded?(file)
  end
  
  def excluded?(file)
    expanded_exclusions().any? do |ex|
      return file =~ ex if ex.respond_to?("~")
      return file == ex
    end
  end

  def expanded_exclusions
    return @expanded_exclusions if @expanded_exclusions

    @exclusions ||= []
    @expanded_exclusions, string_exclusions = @exclusions.partition { |x| x.respond_to?("~") }
    
    @dirs.each do |dir|
      Dir.chdir(dir) do
        string_exclusions.each do |ex|
          exclusions = Dir.glob(ex)
          exclusions = exclusions.map { |x| File.join(dir, x) } unless exclusions[0] == ex
          exclusions << ex if exclusions.empty?
          @expanded_exclusions += exclusions
        end
      end
    end

    @expanded_exclusions
  end
end
