require 'rake'
require 'nokogiri'
require 'fileutils'        
require 'albacore'
require 'albacore/paths'
require 'albacore/cmd_config'
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

        @work_dir   = opts.getopt :work_dir, :default => nil
        @executable = executable
        @parameters = [%W{Pack -OutputDirectory #{opts.getopt(:out)}}].flatten
        @opts = opts

        mono_command
      end

      # run nuget on the nuspec to create a new package
      def execute nuspec_file, nuspec_symbols_file = nil
        debug "NugetsPack::Cmd#execute, opts: #{@opts}"

        orig_pars = @parameters.dup

        pars = orig_pars.dup
        pars << nuspec_file
        system @executable, pars, :work_dir => @work_dir

        # if the symbols flag is set and there's a symbols file specified
        # then run NuGet.exe to generate the .symbols.nupkg file
        if @opts.get :symbols and nuspec_symbols_file
          pars = orig_pars.dup 
          pars << '-Symbols' 
          pars << nuspec_symbols_file 
          system @executable, pars, :work_dir => @work_dir
        else
          debug "symbols not configured for generation, use Config#gen_symbols to do so"
        end
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
    #    p.version = ENV['NUGET_VERSION']
    #    p.gen_symbols
    #  end
    class Config
      include CmdConfig

      # the output directory to place the newfangled nugets in
      attr_writer :out

      # the .net target (e.g. net40, mono2.0)
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

      # gets the options specified for the task
      def opts
        files = @files.respond_to?(:each) ? @files : [@files]
        
        Map.new({
          :out           => @out,
          :exe           => @exe,
          :symbols       => @symbols,
          :package       => @package,
          :target        => @target,
          :files         => @files,
          :configuration => @configuration,
          :original_path => FileUtils.pwd
        })
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
        @files.each do |p|
          proj, n, ns = generate_nuspec p
          execute_inner! proj, n, ns
        end
      end

      def path_to relative_file_path, cwd
        File.expand_path( File.join(@opts.get(:original_path), relative_file_path), cwd )
      end

      # generate all nuspecs
      def generate_nuspecs
        nuspecs = {}
        @files.each do |p|
          proj, n, ns = generate_nuspec p
          #nuspecs[p] = OpenStruct.new({:proj => proj, :nuspec => n, :nuspec_symbols => ns })
          nuspecs[proj.name] = OpenStruct.new({:proj => proj, :nuspec => n, :nuspec_symbols => ns })
        end
        nuspecs
      end

      private
      def generate_nuspec p
        proj = Albacore::Project.new p
        nuspec, nuspec_symbols = create_nuspec proj 
        [proj, nuspec, nuspec_symbols]
      end

      # execute, for each project file
      private
      def execute_inner! proj, nuspec, nuspec_symbols
        nuspec_path = write_nuspec! proj, nuspec
        nuspec_symbols_path = write_nuspec! proj, nuspec_symbols

        create_nuget! proj.proj_path_base, nuspec_path, nuspec_symbols_path
      rescue => e
        err (e.inspect)
        raise $!
      ensure
        #[nuspec_path, nuspec_symbols_path].each{|n| cleanup_nuspec n}
      end

      ## Creating

      private
      def create_nuspec proj
        nuspec = Albacore::NugetModel::Package.from_xxproj proj,
          :project_dependencies => true,
          :nuget_dependencies   => true
        nuspec = nuspec.merge_with(@opts.get(:package))

        nuspec_symbols = Albacore::NugetModel::Package.from_xxproj proj,
          :symbols => true
        nuspec_symbols = nuspec_symbols.merge_with(@opts.get(:package))

        [nuspec, nuspec_symbols]
      end

      private
      def write_nuspec! proj, nuspec
        nuspec_path = File.join(proj.proj_path_base, nuspec.metadata.id + '.nuspec')
        File.write(nuspec_path, nuspec.to_xml)
        nuspec_path
      end

      private
      def create_nuget! cwd, nuspec, nuspec_symbols
        # create the command
        exe = path_to(@opts.get(:exe), cwd)
        out = path_to(@opts.get(:out), cwd)
        nuspec = path_to nuspec, cwd
        nuspec_symbols = path_to nuspec_symbols, cwd
        cmd = Albacore::NugetsPack::Cmd.new(
                exe,
                :work_dir => cwd,
                :out      => out,
                :symbols  => @opts.get(:symbols))

        # run any concerns that modify the command
        @before_execute.call cmd if @before_execute

        debug "generating nuspec at #{nuspec}, and symbols (possibly) at #{nuspec_symbols}"

        # run the command for the file
        cmd.execute nuspec, nuspec_symbols
      end

      ## Cleaning up after generation

      private
      def cleanup_nuspec nuspec
        return if nuspec.nil? or not File.exists? nuspec
        File.delete nuspec
      end

      private
      def publish_artifact! nuspec, nuget
        Albacore.publish :artifact, OpenStruct.new(
          :nuspec   => nuspec,
          :nupkg    => path,
          :location => path
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
