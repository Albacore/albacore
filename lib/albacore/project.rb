require 'nokogiri'
require 'albacore/logging'
require 'albacore/semver'
require 'albacore/package_repo'
require 'albacore/paket'
require 'pathname'

module Albacore
  # error raised from Project#output_path if the given configuration wasn't
  # found
  class ConfigurationNotFoundError < ::StandardError
  end

  class OutputArtifact
    EXECUTABLE = :executable
    LIBRARY = :dll
    XMLDOC = :xmldoc
    SYMBOLS = :symbols

    # E.g. "bin/Debug/lib.dll"
    # E.g. "bin/Debug/net461/lib.dll"
    # E.g. "bin/Debug/net461/lib.xml"
    # E.g. "bin/Debug/net461/lib.dll.pdb"
    # E.g. "bin/Debug/net461/prog.exe"
    attr_reader :path

    # E.g. "lib.dll"
    # E.g. "prog.exe"
    attr_reader :filename

    # E.g. :dll
    attr_reader :sort

    # E.g. ".txt"
    attr_reader :ext

    # Create a new OutputArtifact
    def initialize path, sort
      @path, @sort = path, sort
      @ext = File.extname path
      @filename = File.basename path
    end

    # Is the file a DLL file?
    def library?
      sort == ::LIBRARY
    end

    # Is the file a DLL file?
    def dll?
      library?
    end

    # Is the file an executable?
    def executable?
      sort == ::EXECUTABLE
    end

    # Is the file a documentation file?
    def xmldoc?
      sort == ::XMLDOC
    end

    # Is the file a symbol file?
    def symbols?
      sort == ::SYMBOLS
    end

    def ==(o)
      @path == o.path && @sort == o.sort
    end

    alias_method :eql?, :==
  end

  # A project encapsulates the properties from a xxproj file.
  class Project
    include Logging

    attr_reader \
      :proj_path_base,
      :proj_filename,
      :ext,
      :proj_filename_noext,
      :proj_xml_node

    def initialize proj_path
      raise ArgumentError, 'project path does not exist' unless File.exists? proj_path.to_s
      proj_path                       = proj_path.to_s unless proj_path.is_a? String
      @proj_xml_node                  = Nokogiri.XML(open(proj_path))
      @proj_path_base, @proj_filename = File.split proj_path
      @ext = File.extname @proj_filename
      @proj_filename_noext = File.basename @proj_filename, ext
      sanity_checks
    end

    # Get the project GUID without '{' or '}' characters.
    def guid
      guid_raw.gsub /[\{\}]/, ''
    end

    # Get the project GUID as it is in the project file.
    def guid_raw
      read_property 'ProjectGuid'
    end

    # Get the project id specified in the project file. Defaults to #name.
    def id
      (read_property 'Id') || name
    end

    # Get the project name specified in the project file. This is the same as
    # the title of the nuspec and, if Id is not specified, also the id of the
    # nuspec.
    def name
      read_property('Name') || asmname || proj_filename_noext
    end

    # The same as #name
    alias_method :title, :name

    # The project is a .Net Core project.
    def netcore?
      ! @proj_xml_node.css('Project').attr('Sdk').nil?
    end

    # get the assembly name specified in the project file
    def asmname
      read_property('AssemblyName') || proj_filename_noext
    end

    # Get the root namespace of the project
    def namespace
      read_property 'RootNamespace'
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

    def xmldoc? conf='Debug', platform='AnyCPU'
      if netcore?
        gdf = read_property('GenerateDocumentationFile')
        !gdf.nil? && gdf == 'true'
      else
        ! read_property('DocumentationFile', conf, platform).nil?
      end
    end

    def symbols? conf='Debug', platform='AnyCPU'
      read_property('DebugSymbols', conf) == 'true'
    end

    # OutputArtifact::LIBRARY
    # OutputArtifact::EXECUTABLE
    def output_type
      ot = read_property 'OutputType'
      case ot
      when 'Library'
        OutputArtifact::LIBRARY
      when 'Exe'
        OutputArtifact::EXECUTABLE
      else
        ot
      end
    end

    # ".exe"?, ".dll"?
    def output_file_ext
      case output_type
      when OutputArtifact::LIBRARY
        ".dll"
      when OutputArtifact::EXECUTABLE
        ".exe"
      end
    end

    def default_platform
      @proj_xml_node.css('Project PropertyGroup Platform').first.inner_text || 'AnyCPU'
    end

    def debug_type conf
      dt = read_property "DebugType", conf
    end

    # the target .NET Framework / .NET version
    def target_framework
      read = read_property('TargetFrameworkVersion')
      case read
      when 'v3.5'
        'net35'
      when 'v3.5.1'
        'net351'
      when 'v4.0'
        'net40'
      when 'v4.5'
        'net45'
      when 'v4.5.1'
        'net451'
      when 'v4.6'
        'net46'
      when 'v4.6.1'
        'net461'
      when 'v4.6.2'
        'net462'
      when 'v5.0'
        'net50'
      when 'v5.0.1'
        'net501'
      else
        read
      end
    end

    # Gets the target frameworks as specified by .Net Core syntax
    def target_frameworks
      if netcore?
        tfw = @proj_xml_node.css('Project PropertyGroup TargetFramework').inner_text
        tfws = @proj_xml_node.css('Project PropertyGroup TargetFrameworks').inner_text
        nfws = if tfw.nil? || tfw == '' then tfws else tfw end
        fws = nfws.split(';')
      else
        [ target_framework ]
      end
    end
    
    # Returns OutputArtifact[] or throws an error
    def outputs conf, fw
      os = try_outputs(conf, fw)
      if os.empty?
        raise(ConfigurationNotFoundError, "could not find configuration '#{conf}'")
      else
        os
      end
    end

    def try_outputs conf, fw
      outputs = []
      if netcore? then
        outputs << OutputArtifact.new("bin/#{conf}/#{fw}/#{asmname}#{output_file_ext}", output_type)
        outputs << OutputArtifact.new("bin/#{conf}/#{fw}/#{asmname}.xml", OutputArtifact::XMLDOC) if xmldoc?
      else
        path = read_property 'OutputPath', conf, default_platform
        if path != ''
          full_path = Albacore::Paths.join(path, "#{asmname}#{output_file_ext}").to_s
          outputs << OutputArtifact.new(full_path, output_type)
        end

        if xmldoc? conf, default_platform
          xml_full_path = read_property 'DocumentationFile', conf
          outputs << OutputArtifact.new(xml_full_path, OutputArtifact::XMLDOC)
        end

        if symbols? conf, default_platform
          pdb_full_path = Albacore::Paths.join(path, "#{asmname}.pdb").to_s
          outputs << OutputArtifact.new(pdb_full_path, OutputArtifact::SYMBOLS)
        end
      end
      outputs
    end

    # Gets the relative location (to the project base path) of the dll
    # that it will output
    def output_dll conf, fw
      output_paths(conf, fw).keep_if { |o| o.library? }.first
    end

    # find the NodeList reference list
    def find_refs
      # should always be there
      @proj_xml_node.css("Project Reference")
    end

    def faulty_refs
      find_refs.to_a.keep_if { |r| r.children.css("HintPath").empty? }
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
      @proj_xml_node.css("ProjectReference").collect do |proj_ref|
        debug do
          ref_name = proj_ref.css("Name").inner_text
          "found project reference: #{name} => #{ref_name} [albacore: project]"
        end
        Project.new(File.join(@proj_path_base, Albacore::Paths.normalise_slashes(proj_ref['Include'])))
      end
    end

    # returns a list of the files included in the project
    def included_files
      ['Compile', 'Content', 'EmbeddedResource', 'None'].map { |item_name|
        proj_xml_node.xpath("/x:Project/x:ItemGroup/x:#{item_name}",
                            'x' => "http://schemas.microsoft.com/developer/msbuild/2003").collect { |f|
          debug "#{name}: #included_files looking at '#{f}' [albacore: project]"
          link = f.elements.select { |el| el.name == 'Link' }.map { |el| el.content }.first
          OpenStruct.new(
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

    # Get AssemblyInfo path
    # @return string or project base path if path not found
    def assembly_info_path
      result=@proj_xml_node.css("Compile[Include*='AssemblyInfo']").first #
      p     = if result.nil?
        @proj_path_base
      else
        File.expand_path(File.join(@proj_path_base, '/', Albacore::Paths.normalise_slashes(result.attributes["Include"].value)))
      end
      p
    end

    # Reads assembly version information
    # Returns 1.0.0.0 if AssemblyVersion is not found
    # @return string
    def default_assembly_version
      begin
        info= File.read(assembly_info_path)
        v   = info.each_line
                  .select { |l| !(l.start_with?('//')||l.start_with?('/*')) && l.include?('AssemblyVersion(') }.first
        reg = /"(.*?)"/
        reg.match(v).captures.first
      rescue
        '1.0.0.0'
      end
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

      path = if File.exists?('paket.lock') then
          'paket.lock'
        else
          File.join(@proj_path_base, "paket.lock")
        end

      arr = File.open(path, 'r') do |io|
        lines = io.readlines.map(&:chomp)
        Albacore::Paket.parse_paket_lock(lines)
          .map { |depid, dep|
            [ depid,
              target_frameworks.map { |fw|
                dep2 = OpenStruct.new dep
                dep2[:target_framework] = fw
                dep2
              }
            ]
          }
      end

      @all_paket_deps = Hash[arr]
    end

    def paket_packages
      return nil unless has_paket_deps? || has_paket_refs?
      info { "extracting paket dependencies from '#{to_s}' and 'paket.{dependencies,references}' in its folder [project: paket_package]" }
      all_refs = []

      if has_paket_refs?
        File.open paket_refs, 'r' do |io|
          lines = io.readlines.map(&:chomp)
          lines.compact.each do |line|
            paket_package_by_id! line, all_refs, 'referenced'
          end
        end
      end

      if has_paket_deps?
        File.open paket_deps, 'r' do |io|
          lines = io.readlines.map(&:chomp)
          Albacore::Paket.parse_dependencies_file(lines).each do |line|
            paket_package_by_id! line, all_refs, 'dependent'
          end
        end
      end

      all_refs.uniq
    end

    def paket_package_by_id! id, arr, ref_type
      pkgs = all_paket_deps[id]
      if ! pkgs.nil? && pkgs.length > 0
        debug { "found #{ref_type} package '#{id}' [project: paket_packages]" }
        arr.concat(pkgs)
      else
        warn { "found #{ref_type} package '#{id}' not in paket.lock [project: paket_packages]" }
      end
    end

    def sanity_checks
      warn { "project '#{@proj_filename}' has no name" } unless name
    end

    def read_property prop_name, conf='Debug', platform='AnyCPU'
      specific = @proj_xml_node.css("Project PropertyGroup[Condition*='#{conf}|#{platform}'] #{prop_name}")
      chosen = if specific.empty? then @proj_xml_node.css("Project PropertyGroup #{prop_name}") else specific end
      first = chosen.first
      if first.nil? then nil else first.inner_text end
    end

    # find the node of pkg_id
    def self.find_ref proj_xml, pkg_id
      @proj_xml.css("Project ItemGroup Reference[@Include*='#{pkg_id},']").first
    end
  end

end
