require 'nokogiri'
require 'albacore/logging'
require 'albacore/semver'
require 'albacore/package_repo'

module Albacore

  # error raised from Project#output_path if the given configuration wasn't
  # found
  class ConfigurationNotFoundError < ::StandardError
  end

  # a project encapsulates the properties from a xxproj file.
  class Project
    include Logging

    attr_reader :proj_path_base, :proj_filename, :proj_xml_node

    def initialize proj_path
      raise ArgumentError, 'project path does not exist' unless File.exists? proj_path.to_s
      proj_path = proj_path.to_s unless proj_path.is_a? String
      @proj_xml_node = Nokogiri.XML(open(proj_path))
      @proj_path_base, @proj_filename = File.split proj_path
      sanity_checks
    end

    # Get the project id specified in the project file. Defaults to #name.
    def id
      debug { "Id: #{read_property('Id')}" }
      (read_property 'Id') || name
    end

    # Get the project name specified in the project file. This is the same as
    # the title of the nuspec and, if Id is not specified, also the id of the
    # nuspec.
    def name
      debug { "Name: #{read_property('Name')}" }
      (read_property 'Name') || asmname
    end

    # The same as #name
    alias_method :title, :name

    # get the assembly name specified in the project file
    def asmname
      read_property 'AssemblyName'
    end

    # gets the version from the project file
    def version
      read_property 'Version'
    end

    # gets any authors from the project file
    def authors
      read_property 'Authors'
    end 

    def description
      read_property 'Description'
    end

    # the license that the project has defined in the metadata in the xxproj file.
    def license
      read_property 'License'
    end

    # gets the output path of the project given the configuration or raise
    # an error otherwise
    def output_path conf
      try_output_path conf || raise(ConfigurationNotFoundError, "could not find configuration '#{conf}'")
    end

    def try_output_path conf
      path = @proj_xml_node.css("Project PropertyGroup[Condition*='#{conf}|'] OutputPath")
      # path = @proj_xml_node.xpath("//Project/PropertyGroup[matches(@Condition, '#{conf}')]/OutputPath")

      debug { "#{name}: output path node[#{conf}]: #{ (path.empty? ? 'empty' : path.inspect) } [albacore: project]" }

      return path.inner_text unless path.empty?
      nil
    end

    # This is the output path if the project file doens't have a configured
    # 'Configuration' condition like all default project files have that come
    # from Visual Studio/Xamarin Studio.
    def fallback_output_path
      fallback = @proj_xml_node.css("Project PropertyGroup OutputPath").first
      condition = fallback.parent['Condition'] || 'No \'Condition\' specified'
      warn "chose an OutputPath in: '#{self}' for Configuration: <#{condition}> [albacore: project]"
      fallback.inner_text
    end

    # Gets the relative location (to the project base path) of the dll
    # that it will output
    def output_dll conf
      Paths.join(output_path(conf) || fallback_output_path, "#{asmname}.dll")
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

    def has_paket_deps?
      File.exists? paket_deps
    end

    def has_paket_refs?
      File.exists? paket_refs
    end

    def declared_packages
      return nuget_packages || paket_packages || []
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

    # Find all packages that have been declared and can be found in ./src/packages.
    # This is mostly useful if you have that repository structure.
    # returns enumerable Package
    def find_packages
      declared_packages.collect do |package|
        guess = ::Albacore::PackageRepo.new(%w|./packages ./src/packages|).find_latest package.id
        debug "#{name}: guess: #{guess} [albacore: project]"
        guess
      end
    end

    # get the path of the project file
    def path
      File.join @proj_path_base, @proj_filename
    end

    # save the xml
    def save(output = nil)
      output = path unless output
      File.open(output, 'w') { |f| @proj_xml_node.write_xml_to f }
    end

    # get the full path of 'packages.config'
    def package_config
      File.join @proj_path_base, 'packages.config'
    end

    # Get the full path of 'paket.dependencies'
    def paket_deps
      File.join @proj_path_base, 'paket.dependencies'
    end

    # Get the full path of 'paket.references'
    def paket_refs
      File.join @proj_path_base, 'paket.references'
    end

    # Gets the path of the project file
    def to_s
      path
    end

    private
    def nuget_packages
      return nil unless has_packages_config?
      doc = Nokogiri.XML(open(package_config))
      doc.xpath("//packages/package").collect { |p|
        OpenStruct.new(:id               => p[:id],
                       :version          => p[:version],
                       :target_framework => p[:targetFramework],
                       :semver           => Albacore::SemVer.parse(p[:version], '%M.%m.%p', false)
        )
      }

    end

    def all_paket_deps
      return @all_paket_deps if @all_paket_deps
      arr = File.open('paket.lock', 'r') do |io|
        io.readlines.map(&:chomp).map do |line|
          if (m = line.match /^\s+(?<id>[\w\.]+) \((?<ver>[\.\d\w]+)\)$/i)
            ver = Albacore::SemVer.parse(m[:ver], '%M.%m.%p', false)
            OpenStruct.new(:id               => m[:id],
                           :version          => m[:ver],
                           :target_framework => 'net40',
                           :semver           => ver)
          end
        end.compact.map { |package| [package.id, package] }
      end
      @all_paket_deps = Hash[arr]
    end

    def paket_packages
      return nil unless has_paket_deps? || has_paket_refs?
      info { "extracting paket dependencies from '#{to_s}' and 'paket.{dependencies,references}' in its folder" }

      all_refs = []

      if has_paket_refs?
        File.open paket_refs, 'r' do |io|
          io.readlines.map(&:chomp).each do |line|
            debug { "found referenced package '#{line}' [project paket_packages]" }
            all_refs << all_paket_deps[line]
          end
        end
      end

      if has_paket_deps?
        File.open paket_deps, 'r' do |io|
          io.readlines.map(&:chomp).each do |line|
            debug { "found dependent package '#{line}' [project paket_packages]" }
            all_refs << all_paket_deps[line]
          end
        end
      end

      all_refs
    end

    def sanity_checks
      warn { "project '#{@proj_filename}' has no name" } unless name
    end

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
