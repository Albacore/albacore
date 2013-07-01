require 'fileutils'

module Albacore
  module Tasks

    # Project Lint is a task to check for simple errors in msbuild/project files
    module ProjectLint

      class Config
        attr_accessor :project
        # a list of regex patterns for files in the filesystem to ignore
        attr_accessor :ignores
      end

      # since msbuild projects have a habbit of ignoring case differences, lets use downcase for comparison
      # in windows / and \ can sometimes be used interchangeably 
      class FileReference
        attr_reader :file, :downcase_and_path_replaced
        def initialize file
          @file = file
          @downcase_and_path_replaced = @file.downcase.gsub(/\//,'\\')
        end
        def ==(other)
          other.downcase_and_path_replaced == @downcase_and_path_replaced
        end
        alias_method :eql?, :==
        def hash
          @downcase_and_path_replaced.hash
        end
        def to_s
          @file
        end
      end

      def self.new *sym
        c = Albacore::Tasks::ProjectLint::Config.new
        yield c if block_given?      
        
        body = proc {
          p = Project.new c.project
          ignores = c.ignores 
          ignores = [] if ignores == nil
          ignores += [/^bin/i, /^obj/, # bin, obj usually contain result of compilation
            /csproj$/, /fsproj$/, # project files should not be part of a project file 
            /\.user$/, /\.suo$/ # user settings, source control user settings 
          ]

          files = p.included_files.select { |file|
            file.link == nil
          }.map {|file| FileReference.new(file.include) } 
          srcfolder = File.dirname(c.project)
          fsfiles = nil
          FileUtils.cd (srcfolder) {
            fsfiles = Dir[File.join('**','*.*')].select { |file|
              ! ignores.any? { |r| file.match(r) }
            }.map { |file|
              FileReference.new(file)
            }
          }

          failure_msg = []
          (files-fsfiles).tap do |list|
            if (list.length>0)
              failure_msg.push("- Files in #{c.project} but not on filesystem: \n#{list}")
            end
          end
          (fsfiles-files).tap do |list|
            if (list.length>0)
              failure_msg.push("+ Files not in #{c.project} but on filesystem: \n#{list}")
            end
          end
          fail failure_msg.join("\n") if failure_msg.length>0
        }

        Albacore.define_task *sym, &body
      end


    end
  end
end
