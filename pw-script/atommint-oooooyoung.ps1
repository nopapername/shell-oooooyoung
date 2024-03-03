
$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8
$scriptDir = $PSScriptRoot
$atomicalsjsDir = "D:\atomicals-js"
function Install-NodeJS {
    param (
        [string]$downloadUrl = "https://nodejs.org/dist/v20.10.0/node-v20.10.0-x64.msi",
        [string]$installPath = "D:\Node"
    )
    $DownloadPath = Join-Path $env:TEMP "NodeInstaller.msi"
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $DownloadPath

    Start-Process -Wait -FilePath "msiexec.exe" -ArgumentList "/i", "`"$DownloadPath`"", "/qn", "/norestart", "/L*v `"$InstallPath\install.log`""

    Remove-Item $DownloadPath -Force

    Write-Output "Node install."
}

function Install-Git {
    param(
        [string]$DownloadUrl = "https://github.com/git-for-windows/git/releases/download/v2.43.0.windows.1/Git-2.43.0-64-bit.exe",
        [string]$InstallPath = "D:\Git"
    )

    $DownloadPath = Join-Path $env:TEMP "GitInstaller.exe"
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $DownloadPath

    Start-Process -Wait -FilePath $DownloadPath -ArgumentList "/SILENT", "/COMPONENTS=icons,ext,cmdhere,menus", "/DIR=$InstallPath"

    Remove-Item $DownloadPath -Force

    Write-Output "Git install."
}


function Install-GitRepo {
    param (
        [string]$repoUrl = "https://github.com/atomicals/atomicals-js.git",
        [string]$destination = $atomicalsjsDir
    )

    try {
        if (Test-Path $destination) {
            Remove-Item -Recurse -Force $destination
            Write-Output "Removed existing directory: $destination"
        }

        git clone $repoUrl $destination

        cd $destination

        npm i -g yarn

        yarn install

        yarn build

        Write-Output "Git clone in $destination and install dependencies"
    }
    catch {
        Write-Error "Failed to clone the Git repository. $_"
    }
}

# 安装环境函数
function Install-Env {
 param ()

    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Install-NodeJS
    }
    else {
        Write-Host "Node.js is already installed."
    }

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Install-Git
    }
    else {
        Write-Host "Git is already installed."
    }

 Install-GitRepo

 Write-Output "all env install"
 Read-Host "Press Enter to restart atommint-oooooyoung script..."
 Set-Location -Path $scriptDir
 .\atommint-oooooyoung.ps1
}



# 获取用户输入
$userInput = Read-Host @"
script by oooooyoung11
please select:
1. install atomicals env
2. create wallet
3. import wallet
4. check all wallet info
5. start mint arc20
6. start mint dmint
7. check dmint nft status

"@

# 根据用户输入执行相应操作
switch ($userInput) {
 1 { Install-Env }
 2 { 
     cd $atomicalsjsDir
     & yarn cli wallet-init
     Set-Location -Path $scriptDir
     Read-Host "Press Enter to restart atommint-oooooyoung script..."
     Set-Location -Path $scriptDir
     .\atommint-oooooyoung.ps1
 }
 3 {
     cd $atomicalsjsDir
     $wif = Read-Host "Input wallet WIF private key "
     $alias = Read-Host "Input wallet alias "
     & yarn cli wallet-import $wif $alias
     Read-Host "Press Enter to restart atommint-oooooyoung script..."
     Set-Location -Path $scriptDir
     .\atommint-oooooyoung.ps1
 }
 4 {
     cd $atomicalsjsDir
     & yarn cli wallets
     Read-Host "Press Enter to restart atommint-oooooyoung script..."
     Set-Location -Path $scriptDir
     .\atommint-oooooyoung.ps1
 }
 5 {
     cd $atomicalsjsDir
     $tick = Read-Host "Input mint arc20 coin name "
     $gas = Read-Host "Input mint gas "
     & yarn cli mint-dft $tick --satsbyte $gas*1.2
     Read-Host "Press Enter to restart atommint-oooooyoung script..."
     Set-Location -Path $scriptDir
     .\atommint-oooooyoung.ps1
 }
 6 {
     cd $atomicalsjsDir
     $container = Read-Host "Input container name (start with #) "
     $tick = Read-Host "Input project nft name "
     $dmintpath = Read-Host "Input project json file path "
     $gas = Read-Host "Input mint gas "
     & yarn cli mint-item "$container" "$tick" "$dmintpath" --satsbyte=$gas*1.2
     Read-Host "Press Enter to restart atommint-oooooyoung script..."
     Set-Location -Path $scriptDir
     .\atommint-oooooyoung.ps1
 }
 7 {
     cd $atomicalsjsDir
     $container = Read-Host "Input container name (start with #) "
     $tick = Read-Host "Input project nft name "
     & yarn cli get-container-item "$container" "$tick"
     Read-Host "Press Enter to restart atommint-oooooyoung script..."
     Set-Location -Path $scriptDir
     .\atommint-oooooyoung.ps1
 }
 default { Write-Output "invalid select" }
}
