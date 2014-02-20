# -*- encoding: utf-8 -*-

require 'nokogiri'
require 'pathname'
require 'rake'
require 'albacore/logging'
require 'albacore/project'
require 'albacore/package'
require 'albacore/package_repo'

module Albacore::Tools

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
