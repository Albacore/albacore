require "albacore/albacoretask"
require "erb"
require "ostruct"
require "fileutils"

class Output
  include Albacore::Task

  attr_reader :preserve

  def initialize
    super()

    @files = []
    @erbs = []
    @dirs = []
  end

  def execute()
    unless (@from && @to)
      fail_with_message("output requires #from and #to")
      return
    end

    output = OutputBuilder.new(@from, @to)

    FileUtils.rm_rf(@to) unless @preserve
    FileUtils.mkdir_p(@to)    

    @dirs.each { |dir| output.dir(*dir) }
    @files.each { |file| output.file(*file) }
    @erbs.each { |erb| output.erb(*erb) }
  end

  def from(source)
    @from = source
  end

  def to(source)
    @to = source
  end

  def preserve
    @preserve = true
  end
    
  def file(source, opts = {})
    @files << [source, opts[:as] || source]
  end
  
  def dir(source, opts = {})
    @dirs << [source, opts[:as] || source]
  end
  
  def erb(source, opts = {})
    @erbs << [source, opts[:as] || source, opts[:locals] || {}]
  end
end

class OutputBuilder  
  def initialize(from, to)
    @from = from
    @to = to
  end

  def dir(source, destination)
    from = File.join(@from, source)
    to = File.join(@to, destination)

    FileUtils.cp_r(from, to)
  end
  
  def file(source, destination)
    from = File.join(@from, source)
    to = File.join(@to, destination)

    FileUtils.cp_p(from, to)
  end
  
  def erb(source, destination, locals)
    from = File.join(@from, source)
    to = File.join(@to, destination)

    erb = ERB.new(File.read(from))
    binding = ErbBinding.new(locals)
    content = erb.result(binding.get_binding())
    
    FileUtils.mkdir_p(File.dirname(to))
    File.write(to, content)
  end
end

module FileUtils
  # copy a file, creating the full source, if necessary
  def self.cp_p(source, destination)
    FileUtils.mkdir_p(File.dirname(destination))
    FileUtils.cp(source, destination)
  end
end

class ErbBinding < OpenStruct
  def get_binding
    return binding()
  end
end
