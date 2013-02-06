require 'rake'
require 'albacore/paths'
require 'albacore/cmd_config'
require 'albacore/cross_platform_cmd'
require 'albacore/nugets_authentication'

module Albacore
  module NugetsRestore
    class Cmd
      include Logging
      include CrossPlatformCmd
      def initialize work_dir, executable, *args
        opts = Map.options(args)
        raise ArgumentError, 'pkgcfg is nil' if opts.getopt(:pkgcfg).nil? 
        raise ArgumentError, 'out is nil' if opts.getopts(:out).nil?
        @work_dir = work_dir
        @executable = executable
        @opts = opts

        pars = opts.getopt(:parameters, :default => [])
        if opts.has_key?(:password) && opts.has_key?(:username)
          @authenticate = true
          @username = opts.getopt(:username)
          @password = opts.getopt(:password)
        else
          @authenticate = false
        end
        @parameters = [%W{install #{opts.getopt(:pkgcfg)} -OutputDirectory #{opts.getopt(:out)}}, pars.to_a].flatten
      end
      def write_and_read to_write, stdin, stdout
        to_write.each_char {|c| 
          # initialize buffer for NuGet to write to
          written = ''

          # first write the character
          debug 'writing char'
          stdout.write c
          
          # then read what the process wrote (NuGet will output a '*' after a char is written)
          # http://www.ruby-doc.org/core-1.9.3/IO.html#method-i-read
          # this will be passed to the options for IO#read
          debug 'reading char'
          written = stdin.readchar
          #stdin.read 1, written, :time_out_secs => 1
        
          # echo that
          debug 'writing to stdout'
          STDOUT.write written if written.length > 0
        }
      end
      def execute
        if @authenticate
          debug 'nugets authentication mode - puppeteering NuGet.exe'
          # omg haxxx ;) - feature request to the NuGet team: consume ENV variables
          # so I can avoid hacking like this.
          system_control make_command, :work_dir => @work_dir do |stdin, stdout, stderr, child_proc|
            STDOUT.write(stdout.gets) # => Please provide credentials for ...
            STDOUT.write(stdout.read("Username: ".length, :time_out_secs => 1))
            stdin.puts @username
            STDOUT.puts @username
            debug "reading..."
            STDOUT.write(stdout.read)
            pass = "#{@password}\n"
            debug "writing password..."
            write_and_read pass, stdin, stdout
          end
        else
          debug 'nuget in non-authenticated mode'
          sh @work_dir, make_command
        end
      end
    end
    
    # Public: Configure 'nuget.exe install' -- nuget restore.
    #
    # work_dir - optional
    # exe - required NuGet.exe path
    # out - required location of 'packages' folder
    class Config
      include CmdConfig # => :exe, :work_dir, @parameters, #add_parameter
      include NugetsAuthentication # => :username, :password

      # the output directory passed to nuget when restoring the nugets
      attr_writer :out
    
      def packages
        list_spec = File.join '**', 'packages.config'
        # it seems FileList doesn't care about the curr dir
        in_work_dir do FileList[Dir.glob(list_spec)] end
      end

      def opts_for_pkgcfg pkg
        map = Map.new({ :pkgcfg     => Albacore::Paths.normalize_slashes(pkg),
                        :out        => @out,
                        :parameters => parameters })
        if username && password
          map.set :username, username
          map.set :password, password
        end 
        map
      end
    end

    class Task
      def initialize command_line
        @command_line = command_line
      end
      def execute
        @command_line.execute
      end
    end
  end
end
