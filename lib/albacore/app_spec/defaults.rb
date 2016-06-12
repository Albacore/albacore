require 'albacore/app_spec'
require 'albacore/paths'
# note: this is a Windows provider

module Albacore
  # The default is to get the bin/ folder based on the configuration that you
  # have compiled the project with.
  #
  class AppSpec::Defaults
    include ::Albacore::Logging

    # location/folder inside nuget to place everything found in the
    # #relative_dir inside
    def nuget_contents
      'bin'
    end

    # Where to copy contents from
    def source_dir app_spec, configuration = 'Release'
      Paths.normalise_slashes( File.join(app_spec.proj.proj_path_base,
                app_spec.bin_folder(configuration),
                '.'))
    end

    # create a chocolatey install script for a topshelf service on windows
    #
    # write tools/chocolateyInstall.ps1
    def install_script out, app_spec, &block
      debug { "installing into '#{out}' [app_spec/defaults#install_script]" }
      tools = "#{out}/#{app_spec.id}/tools"

      FileUtils.mkdir tools unless Dir.exists? tools
      File.open(File.join(tools, 'chocolateyInstall.ps1'), 'w+') do |io|
        contents = embedded_resource '../../../resources/chocolateyInstall.ps1'
        io.write contents
        write_invocation app_spec, io
      end
    end

    # Gets the location fully qualified path that the finished artefact will be
    # installed into. Defaults to C:\\Services\\{id}.
    #
    def deploy_dir app_spec
      app_spec.conf['deploy_dir'] || "C:\\Services\\#{app_spec.id}"
    end

    # Get the relative resource from 'albacore/app_spec/.' as a string.
    def embedded_resource relative_path
      File.open(embedded_resource_path(relative_path), 'r') { |io| io.read }
    end

    # Get the relative resource path from 'albacore/app_spec/.'
    def embedded_resource_path relative_path
      File.join(File.dirname(File.expand_path(__FILE__)), relative_path)
    end

    def write_invocation app_spec, io
      debug { 'writing default powershell invocation [app_spec/defaults#write_invocation]' }

      io.write %{
Install-Service `
  -ServiceExeName "#{app_spec.exe}" -ServiceDir "#{deploy_dir app_spec}" `
  -CurrentPath (Split-Path $MyInvocation.MyCommand.Path)
}
    end
  end
end
