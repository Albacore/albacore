require 'spec_helper'
require 'albacore/fluentmigratorrunner'

shared_context "fluentmigrator paths" do
  before :all do
    @command = File.join(File.dirname(__FILE__), 'support', 'Tools', 'FluentMigrator-0.9', 'Migrate.exe')
    @assembly = File.join(File.expand_path(File.dirname(__FILE__)), 'support', 'CodeCoverage', 'fluentmigrator', 'assemblies', 'TestSolution.FluentMigrator.dll')
  end
end

describe FluentMigratorRunner, "the command parameters for an migrator runner" do
  include_context "fluentmigrator paths"
 
  context "Required params" do
    before :all do
      migrator = FluentMigratorRunner.new()
      migrator.command = @command
      @command_parameters = migrator.get_command_parameters.join(" ")
    end

    it "doesn't include command" do
      @command_parameters.should_not include(@command)
    end

    it "includes target" do
      @command_parameters.should include("/target")
    end

    it "includes provider" do
      @command_parameters.should include("/provider")
    end

    it "includes connection" do
      @command_parameters.should include("/connection")
    end  
	end

  context "Optional options" do
    before :all do
      migrator = FluentMigratorRunner.new()
      migrator.command = @command
      migrator.namespace = 'namespace'
      migrator.output_filename = "output.txt"
      migrator.steps = 1
      migrator.task = 'migrate:up'
      migrator.version = '001'
      migrator.script_directory = 'c:\scripts'
      migrator.profile = 'MyProfile'
      migrator.timeout = 90
      migrator.tag = 'MyTag'
      
      @command_parameters = migrator.get_command_parameters.join(" ")
    end

    it "includes ns" do
      @command_parameters.should include('/ns')
    end

    it "includes outfile" do
      @command_parameters.should include('/outfile')
    end 

    it "includes steps" do
      @command_parameters.should include('/steps')
    end

    it "includes task" do
      @command_parameters.should include('/task')
    end

    it "includes version" do
      @command_parameters.should include('/version')
    end

    it "includes wd" do
      @command_parameters.should include('/wd')
    end

    it "includes profile" do
      @command_parameters.should include('/profile')
    end

    it "includes timeout" do
      @command_parameters.should include('/timeout')
    end
    
    it "includes tag" do
      @command_parameters.should include('/tag')
    end
  end

  context "True boolean options" do
    before :all do
      migrator = FluentMigratorRunner.new()
      migrator.command = @command
      migrator.preview
      migrator.output
      migrator.verbose
      
      @command_parameters = migrator.get_command_parameters.join(" ")
    end
    
    it "includes /out when output is true" do
      @command_parameters.should include "/out"
    end
        
    it "includes /preview when preview is true" do
      @command_parameters.should include "/preview"
    end
    
    it "includes /verbose when verbose is true" do
      @command_parameters.should include "/verbose=true"
    end
  end

  context "False boolean options" do
    before :all do
      migrator = FluentMigratorRunner.new()
      migrator.command = @command
      @command_parameters = migrator.get_command_parameters.join(" ")
    end
    
    it "excludes /out when output not true" do
      @command_parameters.should_not include "/out"
    end

    it "excludes /preview when preview is not true" do
      @command_parameters.should_not include "/preview"
    end

    it "excludes /verbose when verbose is not true" do
      @command_parameters.should_not include "/verbose="
    end
  end
end

describe FluentMigratorRunner, "the command line string for an fluentmigrator runner" do
  include_context "fluentmigrator paths"

  before :all do
    migrator = FluentMigratorRunner.new()
    migrator.command = @command
    migrator.target = @assembly    
    @command_line = migrator.get_command_line.join(" ")
    @command_parameters = migrator.get_command_parameters.join(" ")
  end
    
  it "starts with the path to the command" do
    @command_line.should =~ /^#{@command}.*$/
  end
  
  it "includes the command parameters" do
    @command_line.downcase.should include(@command_parameters.downcase)
  end
end
