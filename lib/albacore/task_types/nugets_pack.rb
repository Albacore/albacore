require 'rake'
require 'nokogiri'
require 'fileutils'        
require 'albacore'
require 'albacore/paths'
require 'albacore/cmd_config'
require 'albacore/config_dsl'
require 'albacore/cross_platform_cmd'
require 'albacore/project'
require 'albacore/logging'
require 'albacore/nuget_model'

module Albacore
  module NugetsPack
    # the nuget command
    class Cmd
      include CrossPlatformCmd

      # executable => the nuget executable
      def initialize executable, *args
        opts = Map.options args
        raise ArgumentError, 'out is nil' if opts.getopt(:out).nil?

        @work_dir   = opts.getopt :work_dir, default: nil
        @executable = executable
        @parameters = [%W{Pack -OutputDirectory #{opts.get(:out)}}].flatten
        @opts = opts

        mono_command
      end

      # run nuget on the nuspec to create a new package
      # returns: a tuple-array of the package and the symbol package
      #   of which the symbol package is nil if it was not generated
      def execute nuspec_file, nuspec_symbols_file = nil
        debug "NugetsPack::Cmd#execute, opts: #{@opts} [nugets pack: cmd]"
        original_pars = @parameters.dup

        pars = original_pars.dup
        pars << nuspec_file
        pkg = get_nuget_path_of do
          system @executable, pars, :work_dir => @work_dir
        end

        debug "package at '#{pkg}'"

        # if the symbols flag is set and there's a symbols file specified
        # then run NuGet.exe to generate the .symbols.nupkg file
        if nuspec_symbols_file
          pars = original_pars.dup 
          pars << '-Symbols' 
          pars << nuspec_symbols_file 
          spkg = with_subterfuge pkg do
            get_nuget_path_of do
              system @executable, pars, :work_dir => @work_dir
            end
          end

          debug "symbol package at '#{spkg}'"

          [pkg, spkg]
        else
          info "symbols not configured for generation, use Config#gen_symbols to do so [nugets pack: cmd]"
          [pkg, nil]
        end
      end

      private

      # regexpes the package path from the output
      def get_nuget_path_of
        out = yield
        out.match /Successfully created package '([:\s\w\\\/\d\.]+\.symbols\.nupkg)'./i if out.respond_to? :match
        trace "Got symbols return value: '#{out}', matched: '#{$1}'" if $1
        return $1 if $1

        out.match /Successfully created package '([:\s\w\\\/\d\.]+\.nupkg)'./i if out.respond_to? :match
        trace "Got NOT-symbols return value: '#{out}', matched: '#{$1}'"
        $1
      end

      # hide the original like a ninja while NuGet whimpers in a corner
      def with_subterfuge pkg
        FileUtils.mv pkg, "#{pkg}.tmp" if pkg && File.exists?(pkg)
        res = yield
        FileUtils.mv "#{pkg}.tmp", pkg if pkg && File.exists?("#{pkg}.tmp")
        res
      end
    end
    
    # This tasktype allows you to quickly package project files to nuget
    # packages.
    #
    # Point files to the project files, that should be in MsBuild XML.
    #
    # Examples
    #
    #  nugets_pack :pack => ['build/pkg', :versioning] do |p|
    #    p.files   = FileList['src/**/*.csproj']
    #    p.out     = 'build/pkg'
    #    p.exe     = 'buildsupport/NuGet.exe'
    #    p.with_metadata do |m|
    #      m.version = ENV['NUGET_VERSION']
    #    end
    #    p.gen_symbols
    #    p.no_project_dependencies
    #  end
    class Config
      include CmdConfig
      self.extend ConfigDSL

      # the output directory to place the newfangled nugets in
      attr_path :out

      # the .net target (e.g. net40, mono20, mono3, etc)
      attr_writer :target

      # sets the files to search
      attr_writer :files

      # sets the MsBuild configuration that is used to produce the output into
      # <OutputPath>...</OutputPath>
      attr_writer :configuration

      def initialize
        @package = Albacore::NugetModel::Package.new
        @target  = 'net40'
        @symbols = false
        @project_dependencies = true
        @leave_nuspec = false
        fill_required
      end

      def with_metadata &block
        yield @package.metadata
      end

      # configure the package with a block
      def with_package &block
        yield @package
      end

      # generate symbols for the nugets: just call this method to
      # enable generation
      def gen_symbols
        @symbols = true
      end

      # leave the nuspec behind, don't delete it after generating it
      #
      def leave_nuspec
        @leave_nuspec = true
      end

      # call this if you want to cancel 'smart' scanning of the *proj
      # file for its dependencies
      def no_project_dependencies
        @project_dependencies = false
      end

      # gets the options specified for the task, used from the task
      def opts
        files = @files.respond_to?(:each) ? @files : [@files]

        [:authors, :description, :version].each do |required|
          warn "metadata##{required} is missing from nugets_pack [nugets pack: config]" if @package.metadata.send(required) == 'MISSING' 
        end
        
        Map.new({
          :out           => @out,
          :exe           => @exe,
          :symbols       => @symbols,
          :package       => @package,
          :target        => @target,
          :files         => @files,
          :configuration => @configuration,
          :project_dependencies => @project_dependencies,
          :original_path => FileUtils.pwd,
          :leave_nuspec  => @leave_nuspec
        })
      end

      private

      def fill_required
        # see http://docs.nuget.org/docs/reference/nuspec-reference
        with_metadata do |m|
          m.authors = m.description = m.version = 'MISSING'
        end
      end
    end

    # a task that handles the generation of nugets from projects or nuspecs.
    class ProjectTask
      include Logging

      def initialize opts, &before_execute
        raise ArgumentError, 'opts is not a map' unless opts.is_a? Map
        raise ArgumentError, 'no files given' unless opts.get(:files).length > 0
        @opts           = opts.apply :out => '.'
        @files          = opts.get :files
        @before_execute = before_execute
      end

      def execute
        knowns = compute_knowns
        @files.each do |p|
          proj, n, ns = generate_nuspec p, knowns
          execute_inner! proj, n, ns
        end
      end

      def path_to relative_file_path, cwd
        File.expand_path( File.join(@opts.get(:original_path), relative_file_path), cwd )
      end

      # generate all nuspecs
      def generate_nuspecs
        nuspecs = {}
        knowns = compute_knowns
        @files.each do |p|
          proj, n, ns = generate_nuspec p, knowns
          nuspecs[proj.name] = OpenStruct.new({:proj => proj, :nuspec => n, :nuspec_symbols => ns })
        end
        nuspecs
      end

      private

      def compute_knowns
        Set.new(@files.map { |f| Albacore::Project.new f }.map { |p| p.name })
      end

      def generate_nuspec p, knowns
        proj = Albacore::Project.new p
        nuspec, nuspec_symbols = create_nuspec proj, knowns
        [proj, nuspec, nuspec_symbols]
      end

      # execute, for each project file
      def execute_inner! proj, nuspec, nuspec_symbols
        nuspec_path = write_nuspec! proj, nuspec, false
        nuspec_symbols_path = write_nuspec! proj, nuspec_symbols, true if nuspec_symbols

        create_nuget! proj.proj_path_base, nuspec_path, nuspec_symbols_path
      rescue => e
        err (e.inspect)
        raise $!
      ensure
        trace do
          %{
 PROJECT #{proj.name} nuspec:

#{nuspec.to_xml}

 PROJECT #{proj.name} symbol nuspec:

#{if nuspec_symbols then nuspec_symbols.to_xml else 'NO SYMBOLS' end}}
        end

        # now remove them all
        [nuspec_path, nuspec_symbols_path].each{|n| cleanup_nuspec n}
      end

      ## Creating

      def create_nuspec proj, knowns
        version = @opts.get(:package).metadata.version
        project_dependencies = @opts.get(:project_dependencies, true)
        target = @opts.get :target

        trace "creating NON-SYMBOL package for #{proj.name}, targeting #{target} [nugets pack: task]"
        nuspec = Albacore::NugetModel::Package.from_xxproj proj, 
          symbols:        false,
          verify_files:   true,
          dotnet_version: target,
          known_projects: knowns,
          version:        version,
          configuration:  (@opts.get(:configuration)),
          project_dependencies: project_dependencies

        # take data from package as configured in Rakefile, choosing what is in
        # Rakefile over what is in projfile.
        nuspec = nuspec.merge_with @opts.get(:package)
        trace { "nuspec: #{nuspec.to_s} [nugets pack: task]" }

        if @opts.get(:symbols)
          trace { "creating SYMBOL package for #{proj.name} [nugets pack: task]" }
          nuspec_symbols = Albacore::NugetModel::Package.from_xxproj proj,
            symbols:        true,
            verify_files:   true,
            dotnet_version: target,
            known_projects: knowns,
            version:        version,
            configuration:  (@opts.get(:configuration)),
            project_dependencies: project_dependencies

          nuspec_symbols = nuspec_symbols.merge_with @opts.get(:package)
          trace { "nuspec symbols: #{nuspec_symbols.to_s} [nugets pack: task]" }

          [nuspec, nuspec_symbols]
        else
          trace { "skipping SYMBOL package for #{proj.name} [nugets pack: task]" }
          [nuspec, nil]
        end
      end

      def write_nuspec! proj, nuspec, symbols
        raise ArgumentError, "no nuspect metadata id, project at path: #{proj.proj_path_base}, nuspec: #{nuspec.inspect}" unless nuspec.metadata.id
        nuspec_path = File.join(proj.proj_path_base, nuspec.metadata.id + "#{ symbols ? '.symbols' : '' }.nuspec")

        File.write(nuspec_path, nuspec.to_xml)

        nuspec_path
      end

      def create_nuget! cwd, nuspec, nuspec_symbols = nil
        # create the command
        exe = path_to(@opts.get(:exe), cwd)
        out = path_to(@opts.get(:out), cwd)
        nuspec = path_to nuspec, cwd
        nuspec_symbols = path_to nuspec_symbols, cwd if nuspec_symbols
        cmd = Albacore::NugetsPack::Cmd.new exe,
                work_dir: cwd,
                out:      out

        # run any concerns that modify the command
        @before_execute.call cmd if @before_execute

        debug { "generating nuspec at #{nuspec}, and symbols (possibly) at '#{nuspec_symbols}' [nugets pack: task]" }

        # run the command for the file
        pkg, spkg = cmd.execute nuspec, nuspec_symbols

        publish_artifact nuspec, pkg
        publish_artifact nuspec_symbols, spkg if spkg && nuspec_symbols
      end

      ## Cleaning up after generation

      def cleanup_nuspec nuspec
        return if nuspec.nil? or not File.exists? nuspec
        return if @opts.get :leave_nuspec, false
        File.delete nuspec
      end

      def publish_artifact nuspec, nuget
        Albacore.publish :artifact, OpenStruct.new(
          :nuspec   => nuspec,
          :nupkg    => nuget,
          :location => nuget
        ) 
      end

      def self.accept? f
        File.extname(f).downcase != '.nuspec'
      end
    end
    
    # generate a nuget from a nuspec
    class NuspecTask
      include Logging

      def initialize command_line, config, nuspec
        @config = config
        @nuspec = nuspec
        # is a NuspecPack::Cmd
        @command_line = command_line
      end

      def read_version_from_nuspec
        begin
          nuspec_file = File.open(@nuspec)
          xml = Nokogiri::XML(nuspec_file)
          nuspec_file.close
          nodes = xml.xpath('.//metadata/version')
          raise "No <version/> found" if nodes.empty?
          nodes.first.text()
        rescue => error
          err "Error reading package version from file: #{error}"
          raise
        end
      end
      
      def execute
        version = read_version_from_nuspec
        filename = File.basename(@nuspec, File.extname(@nuspec))

        @command_line.execute @nuspec

        path = File.join(@config.opts.get(:out), "#{filename}.#{version}.nupkg")

        Albacore.publish :artifact, OpenStruct.new(
          :nuspec   => @nuspec,
          :nupkg    => path,
          :location => path
        )
      end

      def self.accept? file
        File.extname(file).downcase == '.nuspec'
      end
    end
  end
end
