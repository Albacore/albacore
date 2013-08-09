# -*- encoding: utf-8 -*-

require 'nokogiri'
require 'pathname'
require 'rake'
require 'albacore/logging'
require 'albacore/project'

module Albacore::Tools
  # a package repository is a location where the nugets or wraps are stored
  class PackageRepo
    include Logging
    # initialize that package repository with a path to all the packages
    def initialize path
      @path = path
    end
    # find the latest package based on the package id
    def find_latest pkg_id
      trace "finding latest from #{@path}, id: #{pkg_id}"
      sorted = Dir.glob(File.join(@path, "#{pkg_id}*/**/*.dll")) # find the latest
      path = sorted.first
      Package.new pkg_id, path
    end
  end

  # a package encapsulates the properties of a set package with a 
  # distinct path, version and id
  class Package
    attr_reader :id, :path
    def initialize id, path
      @id = id
      @path = path
    end
    def path
      @path
    end
    def to_s
      "Package[#{@path}]"
    end
  end

  # a tuple of a package and a ref
  class MatchedRef
    attr_accessor :package, :ref
    def initialize package, ref
      @package, @ref = package, ref
    end
  end

  
  module RestoreHintPaths
    class Config
      attr_accessor :asmname_to_package
      attr_accessor :lang
      attr_accessor :projs, :dry_run
      def initialize
        @asmname_to_package = {}
        @lang = 'fs'
      end
    end
    class Task
      include Logging
      def initialize config
        @config = config
      end
      def execute
        ps = map_file_list(@config.projs) || find_projs_in_need(@config.lang)
        ps.each do |proj|
          info "fixing #{proj}"
          fix_refs proj, @config.asmname_to_package
          info "saving #{proj}"
          proj.save unless @config.dry_run
        end
      end
      
      private
      def find_projs_in_need ext
        map_file_list FileList["./src/**/*.#{ext}proj"]
      end
      def map_file_list fl
        return nil if fl.nil?
        fl.collect{ |path| Project.new(path) }.
           keep_if{ |fp| fp.has_faulty_refs? && fp.has_packages_config? }
      end
      def matched_refs refs, packages, asmname_to_package = {}
        refs.collect { |ref| 
          ref_include_id = asmname_to_package.fetch(ref['Include'].split(',')[0]) { |k| k }
          found_pkg = packages[ref_include_id]
          debug "ref[Include] = #{ref_include_id}, package: #{found_pkg}" unless found_pkg.nil?
          debug "NOMATCH: #{ref_include_id}" if found_pkg.nil?
          found_pkg.nil? ? nil : MatchedRef.new(found_pkg, ref)
        }.keep_if { |match| not match.nil? }
      end

      def fix_refs p, asmname_to_package = {}
        packages = Hash[p.find_packages.collect { |v| [v.id, v] }]
        trace "packages: #{packages}"
        matches = matched_refs p.faulty_refs, packages, asmname_to_package
        trace "matches: #{matches}"
        matches.each{ |match|
          dll_path = Pathname.new match.package.path
          proj_path = Pathname.new p.proj_path_base
          hint_path = Nokogiri::XML::Node.new "HintPath", p.proj_xml_node
          hint_path.content = dll_path.relative_path_from proj_path
          match.ref << hint_path
          debug "For #{p.asmname} => hint_path: #{hint_path}"
        }
        trace p.proj_xml_node
      end
    end
  end
end
