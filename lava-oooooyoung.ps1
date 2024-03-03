$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8

function Test-NodeJSInstalled {
    $nodePath = Get-Command node -ErrorAction SilentlyContinue
    return $nodePath -ne $null
}

function Install-NodeJS {
    param (
        [string]$installPath = "C:\Node"
    )

    $nodeDownloadUrl = "https://nodejs.org/dist/v20.11.1/node-v20.11.1-x64.msi"

    if (Test-NodeJSInstalled) {
        Write-Output "Node.js is already installed."
        return
    }

    New-Item -ItemType Directory -Path $installPath -Force | Out-Null
    Invoke-WebRequest -Uri $nodeDownloadUrl -OutFile "$installPath\node.msi" | Out-Null
    Start-Process -FilePath "$installPath\node.msi" -ArgumentList "/qn" -Wait
    [Environment]::SetEnvironmentVariable("Path", "$($env:Path);$installPath", [EnvironmentVariableTarget]::Machine)
    Remove-Item "$installPath\node.msi" -Force

    Write-Output "Node.js installed."
}

function Install-Env {
    param ()
    Install-NodeJS

    Write-Output "All environment installed."
}

Install-Env
