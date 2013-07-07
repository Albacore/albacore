require 'spec_helper'
require 'albacore/opencoverconsole'

describe OpenCoverConsole do
	before :each do
		@occ = OpenCoverConsole.new
		@occ.extend(SystemPatch)
		@occ.disable_system = true
	end

	it "raises an ArgumentError if the target parameter is not supplied" do
		expect { @occ.execute }.to raise_error(ArgumentError)
	end

	describe "with valid parameters" do
		before :each do
			@occ.target = "test.dll"
		end

		describe "when the command fails" do
			before :each do
				@occ.extend(FailPatch)
				@occ.force_system_failure = true
			end

			it "should return false" do
				@occ.execute
			    $task_failed.should == true
			end

			it "should return the correct message" do
				strio = StringIO.new
				@occ.log_device = strio
				@occ.execute

				strio.string.should include("OpenCover analysis failed.")
			end
		end

		it "should contain a target parameter if it is set" do
			@occ.execute
			@occ.system_command.should match(/\s\"-target:test.dll\"\s?/)
		end

		it "should contain a targetdir parameter if it is set" do
			@occ.target_dir = "test\\"
			@occ.execute
			@occ.system_command.should match(/\s\"-targetdir:test\\\"\s?/)
		end

		it "should contain a targetargs parameter if it is set" do
			@occ.target_args = "/noshadow"
			@occ.execute
			@occ.system_command.should match(/\s\"-targetargs:\/noshadow\"\s?/)
		end

		it "should contain an output parameter if it is set" do
			@occ.output = "results.xml"
			@occ.execute
			@occ.system_command.should match(/\s\"-output:results.xml\"\s?/)
		end

		it "should contain a filter parameter if it is set" do
			@occ.filter = "+[project*]* -[project.Tests*]*"
			@occ.execute
			@occ.system_command.should match(/\s\"-filter:\+\[project\*\]\* -\[project.Tests\*\]\*\"\s?/)
		end

		it "should contain a register parameter if it is set" do
			@occ.register = "user"
			@occ.execute
			@occ.system_command.should match(/\s\"-register:user\"\s?/)
		end

		it "should contain an oldstyle parameter if it is set" do
			@occ.old_style = true
			@occ.execute
			@occ.system_command.should match(/\s-oldStyle\s?/)
		end

		it "should contain an mergebyhash parameter if it is set" do
			@occ.merge_by_hash = true
			@occ.execute
			@occ.system_command.should match(/\s-mergebyhash\s?/)
		end

		it "should contain an nodefaultfilters parameter if it is set" do
			@occ.no_default_filters = true
			@occ.execute
			@occ.system_command.should match(/\s-nodefaultfilters\s?/)
		end

		it "should contain an returntargetcode parameter if it is set" do
			@occ.return_target_code = true
			@occ.execute
			@occ.system_command.should match(/\s-returntargetcode\s?/)
		end
	end
end