require 'albacore/app_spec'
require 'albacore/app_spec/defaults'

module Albacore
  # In the case of building an IIS site we expect the site to have been
  # 'Published' to a specific folder from which we can then fetch the contents.
  #
  # If you want the default behaviour of only packaging the bin/ folder with the
  # compiled artifacts, use 'albacore/app_spec/defaults' instead.
  #
  # While this class is inheriting the defaults, it's still overriding
  # almost/all methods.
  class AppSpec::IisSite < AppSpec::Defaults
    include ::Albacore::Logging
    include ::Albacore::CrossPlatformCmd

    # location/folder inside nuget to place everything found in the
    # #source_dir inside
    #
    def nuget_contents
      'contents'
    end

    # where to copy from - will copy ALL contents of this directory - in this
    # case will copy from the directory that the appspec is in.
    #
    def source_dir app_spec, configuration = 'Release'
      "#{File.dirname(app_spec.path)}/."
    end

    # Extends the outputted data with the installation routines
    #
    def write_invocation app_spec, io
      debug { 'writing iis site installation invocation [app_spec/iis_site#write_invocation]' }

      site_installation_function = embedded_resource '../../../resources/installSite.ps1'
      io.write %{
#{site_installation_function}

# deliberately lowercase id/name/title.
Install-Site -SiteName '#{app_spec.title}' `
    -Port #{app_spec.port} `
    -HostHeader '#{app_spec.host_header}' `
    -WebSiteRootFolder '#{normalise_slashes(deploy_dir(app_spec))}'
}
    end

    # Overrides the default deploy dir with a folder that is NOT services,
    # unless the property is set in the .appspec file.
    #
    def deploy_dir app_spec
      app_spec.conf['deploy_dir'] || "C:\\WebSites"
    end
  end
end
