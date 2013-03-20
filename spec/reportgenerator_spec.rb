require 'spec_helper'
require 'albacore/reportgenerator'

describe ReportGenerator do
	before :each do
		@rg = ReportGenerator.new
		@rg.extend(SystemPatch)
		@rg.disable_system = true
	end	

	it "raises an ArgumentError if the reports parameter is not supplied" do
		@rg.target_dir = "test"
		expect { @rg.execute }.to raise_error(ArgumentError)
	end

	it "raises an ArgumentError if the targetdir parameter is not supplied" do
		@rg.reports = ["results.xml"]
		expect { @rg.execute }.to raise_error(ArgumentError)
	end

	describe "with mandatory parameters" do
		before :each do
			@rg.reports = ["results.xml"]
			@rg.target_dir = "test"
		end

		describe "when the command fails" do
			before :each do
				@rg.extend(FailPatch)
				@rg.force_system_failure = true
			end

			it "should return false" do
				@rg.execute
				$task_failed.should == true
			end

			it "should return the correct error message" do
				strio = StringIO.new
				@rg.log_device = strio
				@rg.execute

				strio.string.should include("Code coverage report generation failed.")
			end
		end

		it "raises an ArgumentError if an invalid report type is supplied" do
			@rg.report_types = [:Invalid]
			expect { @rg.execute }.to raise_error(ArgumentError)
		end

		it "raises an ArgumentError if an invalid verbosity level is supplied" do
			@rg.verbosity = :Invalid
			expect { @rg.execute }.to raise_error(ArgumentError)
		end

		it "should contain a reports parameter if a single report is set" do
			@rg.execute
			@rg.system_command.should match(/\s\"-reports:results.xml\s?\"/)
		end

		it "should contain a reports parameter if multiple reports are set" do
			@rg.reports = ["report1.xml", "report2.xml"]
			@rg.execute
			@rg.system_command.should match(/\s\"-reports:report1.xml;report2.xml\s?\"/)
		end

		it "should contain a targetdir parameter if it is set" do
			@rg.execute
			@rg.system_command.should match(/\s\"-targetdir:test\s?\"/)
		end

		it "should contain a reporttypes parameter if a single report type is set" do
			@rg.report_types = [:Html]
			@rg.execute
			@rg.system_command.should match(/\s-reporttypes:Html\s?/)
		end

		it "should contain a reporttypes parameter if multiple report types are set" do
			@rg.report_types = [:Html, :Xml]
			@rg.execute
			@rg.system_command.should match(/\s-reporttypes:Html;Xml\s?/)
		end

		it "should contain a sourcedirs parameter if a single sourcedir is set" do
			@rg.source_dirs = ["test"]
			@rg.execute
			@rg.system_command.should match(/\s\"-sourcedirs:test\"\s?/)
		end

		it "should contain a sourcedirs parameter if multiple sourcedirs are set" do
			@rg.source_dirs = ["test1", "test2"]
			@rg.execute
			@rg.system_command.should match(/\s\"-sourcedirs:test1;test2\"\s?/)
		end

		it "should contain a filters parameter if a single filter is set" do
			@rg.filters = ["+Included"]
			@rg.execute
			@rg.system_command.should match(/\s\"-filters:\+Included\"\s?/)
		end

		it "should contain a filters parameter if multiple filters are set" do
			@rg.filters = ["+Included", "-Exclude"]
			@rg.execute
			@rg.system_command.should match(/\s\"-filters:\+Included;-Exclude\"\s?/)
		end

		it "should contain a verbosity parameter if it is set" do
			@rg.verbosity = :Verbose
			@rg.execute
			@rg.system_command.should match(/\s-verbosity:Verbose\s?/)
		end
	end
end