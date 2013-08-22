require 'map'
require 'albacore/logging'
require 'albacore/project'
require 'albacore/paths'

module Albacore
  module NugetModel
    class IdVersion
      attr_reader :id, :version
      def initialize id, version
        @id, @version = id, version
      end
      def to_s
        "#{id}@#{version}"
      end
    end

    class FileItem
      attr_reader :src, :target, :exclude
      def initialize src, target, excl
        src, target = Albacore::Paths.normalise_slashes(src),
          Albacore::Paths.normalise_slashes(target)
        @src, @target, @exclude = src, target, excl
      end
      def to_s
        "NugetModel::FileItem(src: #{@src}, target: #{@target}, exclude: #{@exclude}"
      end
    end

    # the nuget xml metadata element writer
    class Metadata
      include Logging

      def self.nuspec_field *syms
        syms.each do |sym|
          self.class_eval(
%{def #{sym}
  @#{sym}
end})
          self.class_eval(
%{def #{sym}= val
  @#{sym} = val
  @set_fields.add? :#{sym}
end})                      
        end 
      end

      # gets or sets the id of this package
      nuspec_field :id
      
      # gets or sets the version of this package
      nuspec_field :version

      # gets or sets the authors of this package
      nuspec_field :authors

      # gets or sets the description of this package
      nuspec_field :description

      # gets or sets the language that this package has been built with
      nuspec_field :language

      # gets or sets the project url for this package
      nuspec_field :project_url

      # gets or sets the license url for this package
      nuspec_field :license_url

      # gets or sets the release notes for this build.
      nuspec_field :release_notes

      # gets or sets the owners of this package
      nuspec_field :owners

      # gets or sets whether this package requires a license acceptance from the user
      # hint: don't.
      nuspec_field :require_license_acceptance

      # gets or sets the copyright for this package
      nuspec_field :copyright

      # get or sets the tags for this package
      nuspec_field :tags

      # get the dependent nuget packages for this package
      nuspec_field :dependencies

      # gets the framework assemblies for this package
      nuspec_field :framework_assemblies

      # gets the field symbols that have been set
      attr_reader :set_fields

      # initialise a new package data object
      def initialize dependencies = nil, framework_assemblies = nil
        @set_fields   = Set.new
        @dependencies = dependencies || Hash.new
        @framework_assemblies = framework_assemblies || Hash.new

        debug "creating new metadata with dependencies: #{dependencies} [nuget model: metadata]" unless dependencies.nil?
        debug "creating new metadata (same as prev) with fw asms: #{framework_assemblies} [nuget model: metadata]" unless framework_assemblies.nil?
      end

      # add a dependency to the package; id and version
      def add_dependency id, version
        @dependencies[id] = IdVersion.new id, version
      end

      # add a framework dependency for the package
      def add_framework_dependency id, version
        @framework_assemblies[id] = IdVersion.new id, version
      end

      def to_xml_builder
        # alt: new(encoding: 'utf-8')
        Nokogiri::XML::Builder.new do |x|
          x.metadata {
            @set_fields.each do |f|
              x.send(Metadata.pascal_case(f), send(f))
            end
            x.dependencies {
              @dependencies.each { |k, d|
                x.dependency id: d.id, version: d.version
              }
            }
          }
        end
      end

      # transform the data structure to the corresponding xml
      def to_xml
        to_xml_builder.to_xml
      end

      def merge_with other
        raise ArgumentError, 'other is nil' if other.nil?
        raise ArgumentError, 'other is wrong type' unless other.is_a? Metadata

        trace { "#{self} merging with #{other} [nuget model: metadata]" }

        deps = @dependencies.clone.merge(other.dependencies)
        fw_asms = @framework_assemblies.clone.merge(other.framework_assemblies)

        m_next = Metadata.new deps, fw_asms

        # set all my fields to the new instance
        @set_fields.each do |field|
          debug "setting field '#{field}' to be '#{send(field)}' [nuget model: metadata]" 
          m_next.send(:"#{field}=", send(field))
        end

        # set all other's fields to the new instance, overriding mine
        other.set_fields.each do |field|
          debug "setting field '#{field}' to be '#{send(field)}' [nuget model: metadata]" 
          m_next.send(:"#{field}=", other.send(field))
        end

        m_next
      end

      def to_s
        "NugetModel::Metadata(#{ @set_fields.map { |f| "#{f}=#{send(f)}" }.join(', ') })"
      end

      self.extend Logging

      def self.from_xml node
        m = Metadata.new
        node.children.reject { |n| n.text? }.each do |n|
          if n.name == 'dependencies'
            n.children.reject { |n| n.text? }.each do |dep|
              m.add_dependency dep['id'], dep['version']
            end
          elsif n.name == 'frameworkDepdendencies'
            n.children.reject { |n| n.text? }.each do |dep|
              m.add_framework_depdendency dep['id'], dep['version']
            end 
          else
            # just set the property
            m.send(:"#{underscore n.name}=", n.inner_text)
          end
        end
        m
      end

      def self.pascal_case str
        str = str.to_s unless str.respond_to? :split
        str = str.split('_').inject([]){ |buffer,e| buffer.push(buffer.empty? ? e : e.capitalize) }.join
        :"#{str}"
      end
      
      def self.underscore str
        str.gsub(/::/, '/').
          gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
          gsub(/([a-z\d])([A-Z])/,'\1_\2').
          tr("-", "_").
          downcase
      end
    end

    # the nuget package element writer
    class Package
      include Logging

      # the metadata corresponds to the metadata element of the nuspec
      attr_accessor :metadata

      # the files is something enumerable that corresponds to the file
      # elements inside '//package/files'.
      attr_accessor :files

      # creates a new nuspec package instance
      def initialize metadata = nil, files = nil
        @metadata = metadata || Metadata.new
        @files = files || []
      end

      # add a file to the instance
      def add_file src, target, exclude = nil
        @files << FileItem.new(src, target, exclude)
        self
      end

      # remove the file denoted by src
      def remove_file src
        src = src.src if src.respond_to? :src # if passed an OpenStruct e.g.
        trace { "remove_file: removing file '#{src}' [nuget model: package]" }
        @files = @files.reject { |f| f.src == src }
      end

      # do something with the metadata.
      # returns the #self Package instance
      def with_metadata &block
        yield @metadata if block_given?
        self
      end

      # gets the current package as a xml builder
      def to_xml_builder
        md = Nokogiri::XML(@metadata.to_xml).at_css('metadata').to_xml
        Nokogiri::XML::Builder.new(encoding: 'utf-8') do |x|
          x.package(xmlns: 'http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd') {
            x << md
            #x.__send__ :insert, md.at_css("metadata")
#           x << md.at_css("metadata").to_xml(indent: 4)
            x.files {
              @files.each do |f|
                if f.exclude
                  x.file src: f.src, target: f.target, exclude: f.exclude
                else
                  x.file src: f.src, target: f.target
                end
              end
            }
          }
        end
      end

      # gets the current package as a xml node
      def to_xml
        to_xml_builder.to_xml
      end

      # creates a new Package/Metadata by overriding data in this instance with
      # data from passed instance
      def merge_with other
        m_next = @metadata.merge_with other.metadata
        files_other = {}
        other.files.each { |f| files_other[f.src] = f }
        f_next = @files.collect { |f| files_other.fetch f.src, f }
        Package.new m_next, f_next
      end

      def to_s
        "NugetModel::Package(files: #{@files.map(&:to_s)}, metadata: #{ @metadata.to_s })"
      end

      # gimme some logging lööve
      self.extend Logging

      # read the nuget specification from a nuspec file
      def self.from_xml xml
        ns = { ng: 'http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd' }
        parser = Nokogiri::XML(xml)
        meta = Metadata.from_xml(parser.xpath('.//ng:metadata', ns))
        files = parser.
          xpath('.//ng:files', ns).
          children.
          reject { |n| n.text? or n['src'].nil? }.
          collect { |n| FileItem.new n['src'], n['target'], n['exclude'] }
        Package.new meta, files
      end

      # read the nuget specification from a xxproj file (e.g. csproj, fsproj)
      def self.from_xxproj_file file, *opts
        proj = Albacore::Project.new file
        from_xxproj proj, *opts
      end

      # Read the nuget specification from a xxproj instance (e.g. csproj, fsproj)
      # Options:
      #  - symbols
      #  - dotnet_version
      #  - known_projects
      #  - configuration
      #  - project_dependencies
      #  - nuget_dependencies
      def self.from_xxproj proj, *opts
        opts = Map.options(opts || {}).
          apply({
            symbols:              false,
            dotnet_version:       'net40',
            known_projects:       Set.new,
            configuration:        'Debug',
            project_dependencies: true,
            verify_files:         false,
            nuget_dependencies:   true })

        trace { "#from_xxproj opts: #{opts} [nuget model: package]" }

        version = opts.get :version
        package = Package.new
        package.metadata.id = proj.name if proj.name
        package.metadata.version = version if version
        package.metadata.authors = proj.authors if proj.authors

        if opts.get :nuget_dependencies
          # add declared packages as dependencies
          proj.declared_packages.each do |p|
            package.metadata.add_dependency p.id, p.version
          end
        end

        if opts.get :project_dependencies
          # add declared projects as dependencies
          proj.
            declared_projects.
            keep_if { |p| opts.get(:known_projects).include? p.name }.
            each do |p|
            debug "adding project dependency: #{proj.name} => #{p.name} at #{version} [nuget model: package]"
            package.metadata.add_dependency p.name, version
          end
        end

        output = proj.output_path(opts.get(:configuration))
        target_lib = %W[lib #{opts.get(:dotnet_version)}].join(Albacore::Paths.separator)

        if opts.get :symbols 
          compile_files = proj.included_files.keep_if { |f| f.item_name == "compile" }

          debug "add compiled files: #{compile_files} [nuget model: package]"
          compile_files.each do |f|
            target = %W[src #{Albacore::Paths.normalise_slashes(f.include)}].join(Albacore::Paths.separator)
            package.add_file f.include, target
          end 

          debug "add dll and pdb files [nuget model: package]"
          package.add_file(Albacore::Paths.normalise_slashes(output + proj.asmname + '.pdb'), target_lib)
          package.add_file(Albacore::Paths.normalise_slashes(output + proj.asmname + '.dll'), target_lib)
        else
          # add *.{dll,xml,config}
          %w[dll xml config].each do |ext|
            file = %W{#{output} #{proj.asmname}.#{ext}}.
              map { |f| f.gsub /\\$/, '' }.
              map { |f| Albacore::Paths.normalise_slashes f }.
              join(Albacore::Paths.separator)
            debug "adding binary file #{file} [nuget model: package]"
            package.add_file file, target_lib
          end
        end

        if opts.get :verify_files
          package.files.each do |file|
            file_path = File.expand_path file.src, proj.proj_path_base
            unless File.exists? file_path
              package.remove_file file.src
              info "while building nuspec for proj: #{proj.name}, file: #{file.src} => #{file.target} not found, removing from nuspec [nuget model: package]"
              trace { "files: #{package.files.map { |f| f.src }.inspect} [nuget model: package]" }
            end
          end
        end

        package
      end
    end
  end
end
