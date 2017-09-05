# encoding: utf-8

require 'map'
require 'albacore/logging'
require 'albacore/project'
require 'albacore/paths'
require 'albacore/tools'

module Albacore
  module NugetModel
    class IdVersion
      attr_reader :id, :version, :group, :target_framework

      def initialize id, version, group, target_framework
        @id, @version, @group, @target_framework = id, version, group, target_framework
      end

      def to_s
        if ! target_framework.nil? && target_framework != ''
          "#{id}@#{version} when #{target_framework}"
        else
          "#{id}@#{version} grouped:#{group}"
        end
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

      # REQUIRED: gets or sets the id of this package
      nuspec_field :id

      # REQUIRED: gets or sets the version of this package
      nuspec_field :version

      # The human-friendly title of the package displayed in the Manage NuGet
      # Packages dialog. If none is specified, the ID is used instead.
      nuspec_field :title

      # REQUIRED: gets or sets a comma-separated string of the authors of this
      # package
      nuspec_field :authors

      # REQUIRED: gets or sets the description of this package
      nuspec_field :description

      # gets or sets the summary of this package
      nuspec_field :summary

      # gets or sets the language that this package has been built with
      nuspec_field :language

      # gets or sets the project url for this package
      nuspec_field :project_url

      # A URL for the image to use as the icon for the package in the Manage
      # NuGet Packages dialog box. This should be a 32x32-pixel .png file that
      # has a transparent background.
      nuspec_field :icon_url

      # gets or sets the license url for this package
      nuspec_field :license_url

      # gets or sets the release notes for this build.
      nuspec_field :release_notes

      # gets or sets the owners of this package
      nuspec_field :owners

      # gets or sets whether this package requires a license acceptance from
      # the user hint: don't set it!
      nuspec_field :require_license_acceptance

      # gets or sets the copyright for this package
      nuspec_field :copyright

      # get or sets the tags for this package
      nuspec_field :tags

      # get the dependent nuget packages for this package
      nuspec_field :dependencies

      # gets the framework assemblies for this package
      nuspec_field :framework_assemblies

      # (v2.5 or above) Specifies the minimum version of the NuGet client that
      # can install this package. This requirement is enforced by both the
      # NuGet Visual Studio extension and .paket/paket.exe program.
      nuspec_field :min_client_version

      # gets the field symbols that have been set
      attr_reader :set_fields

      # initialise a new package data object
      def initialize dependencies = nil, framework_assemblies = nil
        @set_fields   = Set.new
        @dependencies = dependencies || Hash.new
        @framework_assemblies = framework_assemblies || Hash.new
        @has_group = false

        debug "creating new metadata with dependencies: #{dependencies} [nuget model: metadata]" unless dependencies.nil?
        debug "creating new metadata (same as prev) with fw asms: #{framework_assemblies} [nuget model: metadata]" unless framework_assemblies.nil?
      end

      # add a dependency to the package; id and version
      def add_dependency id, version, target_framework = '', group = true
        guard_groups_or_not group
        extra = (target_framework || '') == '' ? '' : "|#{target_framework}"
        @has_group ||= group
        @dependencies["#{id}#{extra}"] = IdVersion.new id, version, group, target_framework
      end

      # add a framework dependency for the package
      def add_framework_dependency id, version, target_framework = '', group = true
        guard_groups_or_not group
        @has_group ||= group
        @framework_assemblies[id] = IdVersion.new id, version, group, target_framework
      end

      def to_template
        lines = []
        lines << 'type file'

        # fields
        @set_fields.each do |f|
          key, value = Metadata.pascal_case(f), send(f)
          if value.is_a?(Array)
            lines << "#{key}"
            value.map{ |line| "  #{line}" }.each do |line|
              lines << line
            end
          else
            lines << "#{key} #{value}"
          end
        end

        lines << 'dependencies' unless @dependencies.empty?
        if @has_group
          groups = @dependencies.group_by { |k, d| d.target_framework }
          groups.each do |group|
            fw, deps = group
            if fw == ''
              deps.each do |k, d|
                lines << "  #{d.id} ~> #{d.version}"
              end
            else
              lines << "  framework: #{fw}"
              deps.each do |k, d|
                lines << "    #{d.id} ~> #{d.version}"
              end
            end
          end
        else
          @dependencies.each do |k, d|
            lines << "  #{d.id} ~> #{d.version}"
          end
        end

        if @framework_assemblies.respond_to?(:each) && @framework_assemblies.length > 0
          lines << 'frameworkAssemblies'
          @framework_assemblies.each do |k, d|
            lines << "  #{d.id}"
          end
        end

        lines
      end

      def to_xml_builder
        # alt: new(encoding: 'utf-8')
        Nokogiri::XML::Builder.new do |x|
          x.metadata do
            @set_fields.each do |f|
              x.send(Metadata.pascal_case(f), send(f))
            end

            x.dependencies do
              if @has_group
                groups = @dependencies.group_by { |k, d| d.target_framework }
                groups.each do |group|
                  fw, deps = group
                  if fw == ''
                    x.group do
                      deps.each do |k, d|
                        x.dependency id: d.id, version: d.version
                      end
                    end
                  else
                    x.group(targetFramework: fw) do
                      deps.each do |k, d|
                        x.dependency id: d.id, version: d.version
                      end
                    end
                  end
                end
              else
                @dependencies.each do |k, d|
                  x.dependency id: d.id, version: d.version
                end
              end
            end

            if @framework_assemblies.respond_to?(:each) && @framework_assemblies.length > 0
              x.frameworkAssemblies do
                @framework_assemblies.each do |k, d|
                  x.frameworkAssembly assemblyName: d.id, targetFramework: d.version
                end
              end
            end
          end
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
            n.children.reject { |n| n.text? }.each do |node|
              if node.name == 'group'
                node.children.reject { |n| n.text? }.each do |dep|
                  tfw = node['targetFramework'] || ''
                  m.add_dependency dep['id'], dep['version'], tfw, group=true
                end
              else
                m.add_dependency node['id'], node['version'], group=false
              end
            end
          elsif n.name == 'frameworkDependencies'
            n.children.reject { |n| n.text? }.each do |node|
              if node.name == 'group'
                node.children.reject { |n| n.text? }.each do |dep|
                  tfw = node['targetFramework'] || ''
                  m.add_framework_dependency dep['id'], dep['version'], tfw, group=true
                end
              else
                m.add_framework_dependency node['id'], node['version'], group=false
              end
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

    private
      def guard_groups_or_not add_in_group
        if @has_group && ! add_in_group \
           || ! @has_group && @dependencies.length > 0 && add_in_group
          raise ArgumentError.new("If you've added dependencies in group, you must add the rest in groups, too. See https://docs.microsoft.com/en-us/nuget/schema/nuspec#framework-assembly-references")
        end
      end
    end

    ############################ PACKAGE

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

      def to_template
        lines = @metadata.to_template

        unless @files.empty?
          lines << 'files'
          @files.each do |file|
            lines << "  #{file.src} ==> #{file.target}" unless file.exclude
            lines << "  !#{file.src}" if file.exclude
          end
        end

        lines
      end

      # gets the current package as a xml builder
      def to_xml_builder
        md = Nokogiri::XML(@metadata.to_xml).at_css('metadata').to_xml
        Nokogiri::XML::Builder.new(encoding: 'utf-8') do |x|
          x.package(xmlns: 'http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd') {
            x << md
            unless @files.empty?
              x.files {
                @files.each do |f|
                  if f.exclude
                    x.file src: f.src, target: f.target, exclude: f.exclude
                  else
                    x.file src: f.src, target: f.target
                  end
                end
              }
            end
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
        files_res = {}

        # my files
        @files.each { |f| files_res[f.src] = f }

        # overrides
        other.files.each { |f| files_res[f.src] = f }

        # result
        f_next = files_res.collect { |k, v| v }

        Package.new m_next, f_next
      end

      def to_s
        "NugetModel::Package(files: #{@files.map(&:to_s)}, metadata: #{ @metadata.to_s })"
      end

      # gimme some logging looove
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
      #   Specifies the version to use for constructing the nuspec's lib folder
      #  - known_projects
      #  - configuration
      #  - project_dependencies
      #   Specifies whether to follow the project dependencies. See nuget_model_spec.rb
      #   for examples of usage of this property.
      #  - nuget_dependencies
      def self.from_xxproj proj, *opts
        opts = Map.options(opts || {}).
          apply({
            symbols:                false,
            known_projects:         Set.new,
            configuration:          'Debug',
            project_dependencies:   true,
            verify_files:           false,
            nuget_dependencies:     true,
            framework_dependencies: true,
            metadata:               Metadata.new })

        trace { "#from_xxproj proj: '#{proj}' opts: #{opts} [nuget model: package]" }

        version = opts.get :version
        package = Package.new(opts.get(:metadata))
        package.metadata.id      = proj.id if proj.id
        package.metadata.title   = proj.name if proj.name
        package.metadata.version = version if version
        package.metadata.authors = proj.authors if proj.authors

        if opts.get :nuget_dependencies
          trace "adding nuget dependencies for id #{proj.id} [nuget model: package]"
          # add declared packages as dependencies
          proj.declared_packages.each do |p|
            # p is a Package
            debug "adding package dependency: #{proj.id} => #{p.id} at #{p.version}, fw #{p.target_framework} [nuget model: package]"
            package.metadata.add_dependency p.id, p.version, p.target_framework, group=true
          end
        end

        if opts.get :project_dependencies
          # add declared projects as dependencies
          proj.
            declared_projects.
            keep_if { |p| opts.get(:known_projects).include? p.id }.
            each do |p|
            # p is a Project
            debug "adding project dependency: #{proj.id} => #{p.id} at #{version}, fw #{p.target_frameworks.inspect} [nuget model: package]"
            p.target_frameworks.each do |fw|
              package.metadata.add_dependency p.id, version, fw, group=true
            end
          end
        end

        fd = opts.get :framework_dependencies
        if fd && fd.respond_to?(:each)
          fd.each { |n, p|
            package.metadata.add_framework_dependency p.id, p.version, p.target_framework, p.group
          }
        end

        debug "including files for frameworks #{proj.target_frameworks.inspect}"
        proj.target_frameworks.each do |fw|
          conf = opts.get(:configuration)

          proj.outputs(conf, fw).each do |output|
            lib_filepath = %W|lib #{fw}|.join(Albacore::Paths.separator)
            debug "adding output file #{output.path} => #{lib_filepath} [nuget model: package]"
            package.add_file output.path, lib_filepath
          end

          if opts.get :sources
            compile_files = proj.included_files.keep_if { |f| f.item_name == "compile" }

            debug "add compiled files: #{compile_files} [nuget model: package]"
            compile_files.each do |f|
              target = %W[src #{Albacore::Paths.normalise_slashes(f.include)}].join(Albacore::Paths.separator)
              package.add_file f.include, target
            end
          end
        end

        if opts.get :verify_files
          package.files.each do |file|
            file_path = File.expand_path file.src, proj.proj_path_base
            unless File.exists? file_path
              info "while building nuspec for proj id: #{proj.id}, file: #{file_path} => #{file.target} not found, removing from nuspec [nuget model: package]"
              package.remove_file file.src
              trace { "files: #{package.files.map { |f| f.src }.inspect} [nuget model: package]" }
            end
          end
        end

        package
      end

      def self.get_output_path proj, opts
        try = proj.try_output_path(opts.get(:configuration))
        return try if try
        warn 'using fallback output path'
        proj.fallback_output_path
      end
    end
  end
end