require 'nokogiri'
require 'albacore/semver'

module Albacore
  # a project encapsulates the properties from a xxproj file.
  class Project
    include Logging
    class << self
      # find the NodeList reference list
      def find_refs proj
        proj.css("Project Reference")
      end
      # find the node of pkg_id
      def find_ref proj_xml, pkg_id
        @proj_xml.css("Project ItemGroup Reference[@Include*='#{pkg_id},']").first
      end
      def asmname proj
        proj.css("Project PropertyGroup AssemblyName").first.content
      end
    end
    
    attr_reader :proj_path_base, :proj_filename, :proj_xml_node
    
    def initialize proj_path
      @proj_xml_node = Nokogiri.XML(open(proj_path))
      @proj_path_base, @proj_filename = File.split proj_path
    end
    
    # get the assembly name
    def asmname
      Project.asmname @proj_xml_node
    end
    
    def find_refs
      Project.find_refs @proj_xml_node
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
    
    def included_files
      ['Compile','Content','EmbeddedResource','None'].map { |elementType|
        proj_xml_node.xpath("/x:Project/x:ItemGroup/x:#{elementType}",
          'x' => "http://schemas.microsoft.com/developer/msbuild/2003").collect { |f|
          # links = f.elements.select{ |el| el.name == 'Link' }
          OpenStruct.new(:include => f[:Include])
        }
      }.flatten()
    end

    # returns enumerable Package
    def find_packages
      declared_packages.collect do |package|
        guess = PackageRepo.new('./src/packages').find_latest package['id']
        debug "guess: #{guess}"
        guess
      end
    end
    
    # get the path
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
  end
end
