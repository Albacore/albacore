module Albacore

  class ExecutableCommand
    attr_accessor :description
    attr_accessor :executable
    attr_accessor :parameters
    attr_accessor :ignored_exitcodes
    def initialise
      description = "no description given"
      executable  = nil
      parameters  = []
      ignored_exitcodes = []
    end
    def execute
      system executable, parameters
    end
    private
    def system *cmd, &block
      block = lambda { |ok, status| ok or fail(format_failure(cmd, status)) } unless block_given?
      opts = Map.options((Hash === cmd.last) ? cmd.pop : {}) # same arg parsing as rake
      pars = cmd[1..-1].flatten

      raise ArgumentError, "arguments 1..-1 must be an array" unless pars.is_a? Array

      exe, pars = ::Albacore::Paths.normalise cmd[0], pars 

      trace "system( exe=#{exe}, pars=#{pars.join(', ')}, options=#{opts.to_s})"

      chdir opts.get(:work_dir) do
        puts %Q{#{exe} #{pars.join(' ')}} unless opts.get :silent, false # log cmd verbatim
        begin
          lines = ''
          IO.popen([exe, *pars]) do |io| # when given a block, returns #IO
            io.each do |line|
              lines << line
              puts line if opts.get(:output, true) or not opts.get(:silent, false)
            end
          end
        rescue Errno::ENOENT => e
          return block.call(nil, PseudoStatus.new(127))
        end
        return block.call($? == 0 && lines, $?)
      end
    end
  end

  class DSLCommand
    require 'map'
    include ExecutableCommand

    def self.new *args
      @opts = Map.options args
    end
    
    def self.description desc
    end

    def self.executable exe
    end

    def self.add_parameter parameter, *opts, &block
      opts = Map.options opts
    end

    def self.ignore_exitcode code
      
    end

    def self.while_running io, &block
      yield io if block_given?
    end

    def self.after_run io, ok, exitcode, &block
      yield io if block_given? 
    end

    def self.before_run executable_cmd, &block
      yield executable_cmd if block_given?
    end
  end

  class SymbolPack < DSLCommand

    description "Runs NuGet pack with symbols"

    executable 'src/vendor/NuGet.exe', :use_mono => true

    add_parameter 'Pack'
    add_parameter '-Symbols'

    add_parameter :nuspec, :type => :string, :windows_slashes => true do |s|
      s.include? '.nuspec'
    end

    ignore_exitcode 22

    onrun do |io|
      io.each do |line|
        Albacore.publish :mycustom, OpenStruct.new({ :line => line })
      end
    end

    onexit do |ok, res|
      puts 'done'
    end

    env 'DEBUG', 'true'

  end 

  task :something do
    cmd = SymbolPack.new :nuspec => 'A/A.nuspec', :work_dir => 'src'
    if File.exists? 'build/myfile.txt'
      cmd.add_parameters %w{--file build/myfile.txt}
    end
    cmd.execute
  end


end
