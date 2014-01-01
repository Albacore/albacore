require "albacore/albacoretask"
require "albacore/config/nuspecconfig"
require "rexml/document"

class NuspecFile
  def initialize(src, target, exclude) 
    @src = src
    @target = target
    @exclude = exclude
  end
  
  def render(xml) 
    depend = xml.add_element("file", { "src" => @src })
    depend.add_attribute("target", @target) if @target
    depend.add_attribute("exclude", @exclude) if @exclude
  end
end

class NuspecDependency
  attr_accessor :id, :version

  def initialize(id, version)
    @id = id
    @version = version
  end
  
  def render(xml)
    depend = xml.add_element("dependency", {"id" => @id, "version" => @version})
  end
end

class NuspecFrameworkAssembly
  attr_accessor :name, :target_framework

  def initialize(name, target_framework)
    @name = name
    @target_framework = target_framework
  end

  def render(xml)
    depend = xml.add_element("frameworkAssembly", {"assemblyName" => @name, "targetFramework" => @target_framework})
  end
end

class NuspecReference
  attr_accessor :file

  def initialize(file)
    @file = file
  end

  def render(xml)
    depend = xml.add_element("reference", {"file" => @file})
  end
end

class Nuspec
  include Albacore::Task
  include Configuration::Nuspec
  
  attr_reader   :pretty_formatting,
                :require_license_acceptance
  
  attr_accessor :id, 
                :version, 
                :title, 
                :description, 
                :language, 
                :license_url, 
                :project_url, 
                :output_file,
                :summary, 
                :icon_url, 
                :copyright,
                :release_notes

  attr_array    :authors,
                :owners,
                :tags

  def initialize()
    @dependencies = []
    @files = []
    @frameworkAssemblies = []
    @references = []
    
    super()
    update_attributes(nuspec.to_hash)
  end

  def pretty_formatting
    @pretty_formatting = true
  end

  def require_license_acceptance
    @require_license_acceptance = true
  end

  def dependency(id, version)
    @dependencies << NuspecDependency.new(id, version)
  end
  
  def file(src, target = nil, exclude = nil)
    @files << NuspecFile.new(src, target, exclude)
  end

  def framework_assembly(name, target_framework)
    @frameworkAssemblies << NuspecFrameworkAssembly.new(name, target_framework)
  end

  def reference(file)
    @references << NuspecReference.new(file)
  end
  
  def execute
    check_required_field(@output_file, "output_file")
    check_required_field(@id, "id")
    check_required_field(@version, "version")
    check_required_field(@authors, "authors")
    check_required_field(@description, "description")
    
    output = ""
    
    builder = REXML::Document.new
    build(builder)
    builder.write(output, @pretty_formatting ? 2 : -1)

    @logger.debug("Writing #{@output_file}")

    File.open(@output_file, "w") { |f| f.write(output) }
  end

  def build(document)
    document << REXML::XMLDecl.new

    package = document.add_element("package")
    package.add_attribute("xmlns", "http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd")

    metadata = package.add_element("metadata")
    metadata.add_element("id").add_text(@id)
    metadata.add_element("version").add_text(@version)
    metadata.add_element("title").add_text(@title) if @title
    metadata.add_element("authors").add_text(@authors.join(", "))
    metadata.add_element("description").add_text(@description)
    metadata.add_element("releaseNotes").add_text(@release_notes)
    metadata.add_element("copyright").add_text(@copyright)
    metadata.add_element("language").add_text(@language) if @language
    metadata.add_element("licenseUrl").add_text(@license_url) if @license_url
    metadata.add_element("projectUrl").add_text(@project_url) if @project_url
    metadata.add_element("owners").add_text(@owners.join(", ")) if @owners
    metadata.add_element("summary").add_text(@summary) if @summary
    metadata.add_element("iconUrl").add_text(@icon_url) if @icon_url
    metadata.add_element("requireLicenseAcceptance").add_text("true") if @require_license_acceptance
    metadata.add_element("tags").add_text(@tags.join(" ")) if @tags

    if @dependencies.length > 0
      depend = metadata.add_element("dependencies")
      @dependencies.each { |x| x.render(depend) }
    end

    if @files.length > 0
      files = package.add_element("files")
      @files.each { |x| x.render(files) }
    end
	
    if @frameworkAssemblies.length > 0
      depend = metadata.add_element("frameworkAssemblies")
      @frameworkAssemblies.each { |x| x.render(depend) }
    end

    if @references.length > 0
      depend = metadata.add_element("references")
      @references.each { |x| x.render(depend) }
    end
  end

  def check_required_field(field, fieldname)
    raise "nuspec requires \"#{fieldname}\"" unless field
  end
end
