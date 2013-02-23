require 'albacore/albacoretask'
require 'rexml/document'
require 'fileutils'

class CsProjFiles 
  include Albacore::Task
  include Configuration::CsProjFiles
  attr_accessor :project
  attr_array :ignore_files
  
  def initialize
    @ignore_files = []
    super()
    update_attributes csprojfiles.to_hash
  end
    
  def execute
    proj=CsProjReader.new(File.open(@project).read)
    srcfolder = File.dirname(@project)
    files = proj.files.map do |file|
      FileReference.new(file)
    end
    ignores = [/^bin/i, /^obj/, /csproj$/, /\.user$/]
    ignores += @ignore_files
    fsfiles = nil
    FileUtils.cd (srcfolder) do
      fsfiles = Dir[File.join('**','*.*')].select do |file|
        ! ignores.any? { |r| file.match(r) }
      end.map do |file|
        FileReference.new(file)
      end
    end

    failure_msg = []
    (files-fsfiles).tap do |list|
      if (list.length>0)
        failure_msg.push("- Files in #{@project} but not on filesystem: \n#{list}")
      end
    end
    (fsfiles-files).tap do |list|
      if (list.length>0)
        failure_msg.push("+ Files not in #{@project} but on filesystem: \n#{list}")
      end
    end

    fail_with_message failure_msg.join("\n") if failure_msg.length>0
  end

  private
  # implementation details
  class CsProjReader
    attr_reader :content
    def initialize(content)
      @content = content
      @xmldoc = REXML::Document.new(@content)
      @xmlns = {"x"=>"http://schemas.microsoft.com/developer/msbuild/2003"};
    end

    def files()
      files=[]
      ['Compile','Content','EmbeddedResource','None'].each { |elementType|
          REXML::XPath.each(@xmldoc,"/x:Project/x:ItemGroup/x:#{elementType}", @xmlns) { |file|
            links = file.elements.select{ |el| el.name == 'Link' }
            if (links.length==0)
              files.push(file.attributes['Include'])
            end
          }
      }
      return files
    end
  end

  class FileReference
    attr_reader :file, :downcase_and_path_replaced
    def initialize file
      @file = file
      @downcase_and_path_replaced = @file.downcase.gsub(/\//,'\\')
    end
    def ==(other)
      other.downcase_and_path_replaced == @downcase_and_path_replaced
    end
    alias_method :eql?, :==
    def hash
      @downcase_and_path_replaced.hash
    end
    def to_s
      @file
    end
  end

end
