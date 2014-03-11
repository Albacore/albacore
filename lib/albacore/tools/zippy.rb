# encoding: utf-8
require 'zip'
require "albacore"

# https://github.com/aussiegeek/rubyzip/blob/master/samples/example_recursive.rb
# This is a simple example which uses rubyzip to
# recursively generate a zip file from the contents of
# a specified directory. The directory itself is not
# included in the archive, rather just its contents.
#
# Usage:
# dir_to_zip = "/tmp/input"
# out_file = "/tmp/out.zip"
# zf = Zippy.new dir_to_zip, out_file
# zf.write
#
# Or:
# z = Zippy.new(directory_to_zip, output_file) { |f| f.include? 'html' }
# z.write
class Zippy

  # Initialize with the directory to zip and the location of the output archive.
  #
  # @param [String] input_dir The location to zip as a file system relative or
  #                           absolute path
  #
  # @param [String] out_file The path of the output zip file that is generated.
  # @param [Block] filter An optional block with a filter that is to return true
  #                       if the file is to be added.
  def initialize input_dir, out_file, &filter
    @input_dir = input_dir.
      gsub(/[\/\\]$/, '').
      gsub(/\\/, '/')
    @out_file = out_file
    @filter = block_given? ? filter : lambda { |f| true }
  end

  # Zips the input directory.
  def write
    FileUtils.rm @out_file if File.exists? @out_file
    in_progress "Writing archive #{@out_file} from #{@input_dir}" do
      Zip::File.open @out_file, Zip::File::CREATE do |zipfile|
        Dir["#{@input_dir}/**/**"].reject{ |f| f == @out_file || !@filter.call(f) }.each do |file|
          progress "deflating #{file}"
          zipfile.add(file.sub(@input_dir + '/', ''), file)
        end
      end
	end
  end
  
  private
  def in_progress msg, &block
    Albacore.publish :start_progress, OpenStruct.new(:message => msg)
    yield
    Albacore.publish :finish_progress, OpenStruct.new(:message => msg)
  end

  def progress msg
    Albacore.publish :progress, OpenStruct.new(:message => msg)
  end
end
