Import-Module WebAdministration

Function Install-Site(
    # Folder where all your websites are located
    [string] $WebSiteRootFolder = "C:\WebSites",

    # The port your default binding is using
    [int] $Port = 80,

    # Where the source files are -- without any trailing slash or otherwise --
    # just the name, please.
    [string] $SourceDirectory = "source",

    # Name of site that you're setting up
    [string] $SiteName
) {
    #site folder
    $siteInstallLocation = "$WebSiteRootFolder\$SiteName"

    #site application pool
    $siteAppPool = "$SiteName-pool"

    #check if the site is already present (determines update or install)
    $isPresent = Get-Website -name $siteName 

    if($isPresent){
        # Upgrade the current package
        Write-Host "$SiteName will be updated"
        Copy-Item "$SourceDirectory\*" -Recurse $siteInstallLocation -Force
    } else {
        # Install a clean version of the package

        Write-Host "$SiteName will be installed"

        # Create site folder
        new-item $siteInstallLocation -ItemType directory -Force

        # Copy site files to site folder
        Copy-Item $SourceDirectory -Recurse $siteInstallLocation -Force

        # Create application pool
        New-WebAppPool -Name $siteAppPool -Force

        $hostHeader = Invoke-Expression "facter fqdn"

        # Create site
        New-Website -Name $SiteName -Port $Port -HostHeader $hostHeader `
            -ApplicationPool $siteAppPool -PhysicalPath $siteInstallLocation
    }
}
