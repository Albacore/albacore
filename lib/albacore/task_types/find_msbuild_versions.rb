require 'rake'
module Albacore
  def self.find_msbuild_versions
    return nil unless ::Rake::Win32.windows?
    require 'win32/registry'
    retval = Hash.new
    begin
      Win32::Registry::HKEY_LOCAL_MACHINE.open('SOFTWARE\Microsoft\MSBuild\ToolsVersions') do |toolsVersion|
        toolsVersion.each_key do |key|
          begin
            versionKey = toolsVersion.open(key)
            version = key.to_i
            msb = File.join(versionKey['MSBuildToolsPath'],'msbuild.exe')
            retval[version] = msb
          rescue
            error "failed to open #{key}"
          end
        end
      end
    rescue
      error "failed to open HKLM\\SOFTWARE\\Microsoft\\MSBuild\\ToolsVersions"
    end
	
	# MSBuild 15, assume default installation path
	vs2017_dir = Dir[File.join(ENV['ProgramFiles(x86)'].gsub('\\', '/'), 'Microsoft Visual Studio', '2017', '*')].first
	retval[15] = File.join(vs2017_dir, 'MSBuild', '15.0', 'Bin') unless vs2017_dir.nil?
	
    return retval
  end
end