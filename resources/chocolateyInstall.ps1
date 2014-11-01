$ErrorActionPreference = "Stop"

Function Resolve-Error($ErrorRecord = $Error[0]) {
   $ErrorRecord | Format-List * -Force
   $ErrorRecord.InvocationInfo | Format-List *
   $Exception = $ErrorRecord.Exception
   for ($i = 0; $Exception; $i++, ($Exception = $Exception.InnerException))
   {   "$i" * 80
       $Exception | Format-List * -Force
   }
}

Function Check-Exit($Output) {
    if (-not $?) {
        throw "Last command exited with $($LASTEXITCODE)"
    }
}

Function System([string] $Command, [Switch] $Silent) {
    if ($Silent) {
        Invoke-Expression $Command | Tee-Object -Variable scriptOutput | Out-Null
    } else {
        Invoke-Expression $Command | Tee-Object -Variable scriptOutput
    }
    Check-Exit $scriptOutput
}

Function Get-ServiceVersion([string] $ServiceExePath) {
    try{
        (ls $ServiceExePath | Select-Object -First 1).VersionInfo.FileVersion.ToString()
    } catch {
        throw (New-Object System.InvalidOperationException "$ServiceExeName is missing a fileversion, did you add a assembly version to it?")
    }
}

Function Copy-WithBackup([string] $Source, [string] $Target, [string] $ServiceExePath) {
    if ([string]::IsNullOrWhiteSpace($Source)) {
        throw (New-Object System.ArgumentNullException "Source - Copy-WithBackup")
    }
    if ([string]::IsNullOrWhiteSpace($Target)) {
        throw (New-Object System.ArgumentNullException "Target - Copy-WithBackup")
    }
    if ([string]::IsNullOrWhiteSpace($ServiceExePath)) {
        throw (New-Object System.ArgumentNullException "ServiceExePath - Copy-WithBackup")
    }
    #Start-Transaction -Timeout 2
    try {
        # don't have to -UseTransaction, as tx equiv. to FS state here
        if (Test-Path -Path $Target) {
            $oldVersion = Get-ServiceVersion $ServiceExePath
            $backup = "$Target-$oldVersion"

            Write-Host -ForegroundColor Green "Using backup folder '$backup'"
            if (Test-Path $backup) {
                Remove-Item -Path $backup -Force -Recurse
            }
            Move-Item $Target $backup -Force #-UseTransaction
        }
        
        Write-Host -ForegroundColor Green "Copy-Item -Recurse $Source $Target"
        New-Item -ItemType Directory -Path $Target | Out-Null
        Copy-Item -Recurse $Source $Target #-UseTransaction
        #Complete-Transaction
    } catch {
        #Undo-Transaction
        throw
    }
}

Function Invoke-WithStoppedTopshelf([string] $ServiceExePath, [scriptblock] $WhileStopped) {
    if ([string]::IsNullOrWhiteSpace($ServiceExePath)) {
        throw (New-Object System.ArgumentNullException "ServiceExePath - Invoke-WithStoppedTopshelf")
    }

    if (Test-Path -Path $ServiceExePath) {
        Write-Host -ForegroundColor Green "$ServiceExePath uninstall"
        System "$ServiceExePath uninstall" -Silent
    }
    try {
        Invoke-Command -ScriptBlock $WhileStopped
    } finally {
        if (Test-Path -Path $ServiceExePath) {
            Write-Host -ForegroundColor Green "$ServiceExePath install"
            System "$ServiceExePath install" -Silent
        
            Write-Host -ForegroundColor Green "$ServiceExePath start"
            System "$ServiceExePath start" -Silent
        } else {
            Write-Host -ForegroundColor Yellow "Path $ServiceExePath doesn't exist"
        }
    }
}

Function Install-Service([string] $ServiceExeName,
                         [string] $ServiceDir,
                         [string] $CurrentPath = $(Get-Location).Path) {
    if ([string]::IsNullOrWhiteSpace($ServiceExeName)) {
        throw (New-Object System.ArgumentNullException "ServiceExeName - Install-Service")
    }
    if ([string]::IsNullOrWhiteSpace($ServiceDir)) {
        throw (New-Object System.ArgumentNullException "ServiceDir - Install-Service")
    }
    if ([string]::IsNullOrWhiteSpace($CurrentPath)) {
        throw (New-Object System.ArgumentNullException "CurrentPath - Install-Service")
    }

    # relative to chocolatey
    $parentDir = Split-Path -Parent $CurrentPath
    # get binaries' dir's contents
    $bin = Join-Path $parentDir "bin\*"
    
    try {
        $serviceExePath = Join-Path $ServiceDir $ServiceExeName
        Invoke-WithStoppedTopshelf -ServiceExePath $serviceExePath {
            Copy-WithBackup -Source $bin -Target $ServiceDir -ServiceExePath $serviceExePath
        }
        # Write-Host -ForegroundColor Green "Successfully installed $ServiceExeName" # OR:
        Write-ChocolateySuccess "The service was succesfully installed"
    } catch {
        Resolve-Error $_.Exception
        Write-ChocolateyFailure 'Failed to install service'
        throw
    }
}
