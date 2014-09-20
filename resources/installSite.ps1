Import-Module WebAdministration

Function Install-Site(
    # Folder where all your websites are located
    [string] $WebSiteRootFolder = "C:\WebSites",

    # What domain name the site should bind to
    [string] $HostHeader,

    # The port your default binding is using
    [int] $Port,

    # Name of site that you're setting up
    [string] $SiteName
) {

    $scriptDir = Split-Path -Parent $MyInvocation.PSCommandPath
    $parentDir = Split-Path -Parent $scriptDir
    $source = Join-Path $parentDir "contents\*"

    #site folder
    $siteInstallLocation = "$WebSiteRootFolder\$SiteName"

    #site application pool
    $siteAppPool = "$SiteName-pool"

    #check if the site is already present (determines update or install)
    $isPresent = Get-Website -name $siteName

    if($isPresent){
        # Upgrade the current package
        Write-Host -ForegroundColor Yellow "$SiteName will be updated"
        Copy-Item "$source" -Recurse $siteInstallLocation -Force
        Write-Host -ForegroundColor Green "$SiteName is updated"
    } else {
        # Install a clean version of the package

        Write-Host "$SiteName will be installed"

        # Create site folder
        new-item $siteInstallLocation -ItemType directory -Force

        # Copy site files to site folder
        Copy-Item $source -Recurse $siteInstallLocation -Force

        # Create application pool
        New-WebAppPool -Name $siteAppPool -Force

        # Create site
        New-Website -Name $SiteName -Port $Port -HostHeader $HostHeader `
            -ApplicationPool $siteAppPool -PhysicalPath $siteInstallLocation
    }
}

