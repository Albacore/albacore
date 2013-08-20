require 'nokogiri'
require 'albacore/semver'

module Albacore
  # a project encapsulates the properties from a xxproj file.
  class Project
    include Logging

    attr_reader :proj_path_base, :proj_filename, :proj_xml_node
    
    def initialize proj_path
      @proj_xml_node = Nokogiri.XML(open(proj_path))
      @proj_path_base, @proj_filename = File.split proj_path
    end
    
    # get the project name specified in the project file
    def name
      prop = read_property 'Name' || asmname
      prop || asmname
    end

    # get the assembly name specified in the project file
    def asmname
      read_property 'AssemblyName'
    end

    # gets the version from the project file
    def version
      read_property "Version"
    end

    # gets any authors from the project file
    def authors
      read_property "Authors"
    end 

    # gets the output path of the project given the configuration
    def output_path conf
      path = @proj_xml_node.css("Project PropertyGroup[Condition*=#{conf}] OutputPath")
      debug "#{name}: output path node[#{conf}]: #{ (path.empty? ? 'empty' : path.inspect) } [albacore: project]"
      return path.inner_text unless path.empty?

      path = @proj_xml_node.css("Project PropertyGroup OutputPath")
      path.inner_text
    end
    
    # find the NodeList reference list
    def find_refs
      # should always be there
      @proj_xml_node.css("Project Reference")
    end
    
    def faulty_refs
      find_refs.to_a.keep_if{ |r| r.children.css("HintPath").empty? }
    end
    
    def has_faulty_refs?
      faulty_refs.any?
    end
    
    def has_packages_config?
      File.exists? package_config
    end

    def declared_packages
      return [] unless has_packages_config?
      doc = Nokogiri.XML(open(package_config))
      doc.xpath("//packages/package").collect { |p|
        OpenStruct.new(:id => p[:id], 
          :version => p[:version], 
          :target_framework => p[:targetFramework],
          :semver => Albacore::SemVer.parse(p[:version], '%M.%m.%p', false)
        )
      }
    end

    def declared_projects
      @proj_xml_node.css("ProjectReference").collect do |proj|
        debug "#{name}: found project reference: #{proj.css("Name").inner_text} [albacore: project]"
        Project.new(File.join(@proj_path_base, Albacore::Paths.normalise_slashes(proj['Include'])))
        #OpenStruct.new :name => proj.inner_text
      end
    end

    # returns a list of the files included in the project
    def included_files
      ['Compile','Content','EmbeddedResource','None'].map { |item_name|
        proj_xml_node.xpath("/x:Project/x:ItemGroup/x:#{item_name}",
          'x' => "http://schemas.microsoft.com/developer/msbuild/2003").collect { |f|
          debug "#{name}: #included_files looking at '#{f}' [albacore: project]"
          link = f.elements.select{ |el| el.name == 'Link' }.map { |el| el.content }.first
          OpenStruct.new(:include => f[:Include], 
            :item_name => item_name.downcase,
            :link      => link,
            :include   => f['Include']
          )
        }
      }.flatten
    end

    # returns enumerable Package
    def find_packages
      declared_packages.collect do |package|
        guess = PackageRepo.new('./src/packages').find_latest package['id']
        debug "#{name}: guess: #{guess} [albacore: project]"
        guess
      end
    end
    
    # get the path of the project file
    def path
      File.join @proj_path_base, @proj_filename
    end
    
    # save the xml
    def save
      File.open(path, 'w') { |f| @proj_xml_node.write_xml_to f }
    end
    
    # get the path of 'packages.config'
    def package_config
      File.join @proj_path_base, 'packages.config'
    end
    
    def to_s
      path
    end

    private

    def read_property prop_name
      txt = @proj_xml_node.css("Project PropertyGroup #{prop_name}").inner_text
      txt.length == 0 ? nil : txt.strip
    end

    # find the node of pkg_id
    def self.find_ref proj_xml, pkg_id
      @proj_xml.css("Project ItemGroup Reference[@Include*='#{pkg_id},']").first
    end
  end
end
