$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8

function Test-CommandInstalled {
    param(
        [string]$command
    )
    return Get-Command $command -ErrorAction SilentlyContinue
}

function Install-NodeJS {
    param (
        [string]$installPath = "C:\Node"
    )

    # Check if Node.js is already installed
    if (Test-CommandInstalled "node") {
        Write-Output "Node.js is already installed."
        return
    }

    $nodeDownloadUrl = "https://nodejs.org/dist/v20.11.1/node-v20.11.1-x64.msi"

    New-Item -ItemType Directory -Path $installPath -Force | Out-Null
    Invoke-WebRequest -Uri $nodeDownloadUrl -OutFile "$installPath\node.msi" | Out-Null
    Start-Process -FilePath "$installPath\node.msi" -ArgumentList "/qn" -Wait
    [Environment]::SetEnvironmentVariable("Path", "$($env:Path);$installPath", [EnvironmentVariableTarget]::Machine)
    Remove-Item "$installPath\node.msi" -Force

    Write-Output "Node.js installed."
}

function Install-Git {
    param (
        [string]$installPath = "C:\Git"
    )

    # Check if Git is already installed
    if (Test-CommandInstalled "git") {
        Write-Output "Git is already installed."
        return
    }

    $gitDownloadUrl = "https://github.com/git-for-windows/git/releases/download/v2.43.0.windows.1/Git-2.43.0-64-bit.exe"

    New-Item -ItemType Directory -Path $installPath -Force | Out-Null
    Invoke-WebRequest -Uri $gitDownloadUrl -OutFile "$installPath\Git-Installer.exe" | Out-Null
    Start-Process -FilePath "$installPath\Git-Installer.exe" -ArgumentList "/SILENT" -Wait
    [Environment]::SetEnvironmentVariable("Path", "$($env:Path);$installPath\cmd;$installPath\bin", [EnvironmentVariableTarget]::Machine)
    Remove-Item "$installPath\Git-Installer.exe" -Force

    Write-Output "Git installed."
}

function Install-GitRepo {
    param (
        [string]$repoUrl = "https://github.com/nopapername/shell-oooooyoung.git",
        [string]$destination = "$([System.IO.Path]::Combine($env:USERPROFILE, 'Desktop\shell-oooooyoung'))"
    )

    if (Test-Path $destination) {
        Write-Output "Repository already exists on the desktop. Removing and re-cloning."
        Remove-Item -Recurse -Force $destination
    }

    git clone $repoUrl $destination
    Set-Location $destination
    npm install

    Write-Output "Git clone in $destination and install dependency"
}

function Start-NodeScript {
    param (
        [string]$scriptPath = "$([System.IO.Path]::Combine($env:USERPROFILE, 'Desktop\shell-oooooyoung\js-script\lava-oooooyoung.js'))"
    )

    if (Test-Path $scriptPath) {
        Write-Output "Executing Node.js script: $scriptPath"
        node $scriptPath
    } else {
        Write-Error "Node.js script not found at: $scriptPath"
    }
}

function Install-Env {
    param ()
    Install-NodeJS
    Install-Git
    Install-GitRepo

    Write-Output "All environment installed."
    Read-Host "Press Enter to restart lava-oooooyoung.js script..."
    Start-NodeScript
}

Install-Env
