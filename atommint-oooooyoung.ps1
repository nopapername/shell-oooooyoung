
$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8
function Install-NodeJS {
 param (
     [string]$installPath = "C:\Node"
 )

 $nodeDownloadUrl = "https://nodejs.org/dist/v20.10.0/node-v20.10.0-x64.msi"

 New-Item -ItemType Directory -Path $installPath -Force | Out-Null
 Invoke-WebRequest -Uri $nodeDownloadUrl -OutFile "$installPath\node.msi" | Out-Null
 Start-Process -FilePath "$installPath\node.msi" -ArgumentList "/qn" -Wait
 [Environment]::SetEnvironmentVariable("Path", "$($env:Path);$installPath", [EnvironmentVariableTarget]::Machine)
 Remove-Item "$installPath\node.msi" -Force

 Write-Output "Node.js install."
}


function Install-Git {
 param (
     [string]$installPath = "C:\Git"
 )

 $gitDownloadUrl = "https://github.com/git-for-windows/git/releases/download/v2.43.0.windows.1/Git-2.43.0-64-bit.exe"

 New-Item -ItemType Directory -Path $installPath -Force | Out-Null
 Invoke-WebRequest -Uri $gitDownloadUrl -OutFile "$installPath\Git-Installer.exe" | Out-Null
 Start-Process -FilePath "$installPath\Git-Installer.exe" -ArgumentList "/SILENT" -Wait
 [Environment]::SetEnvironmentVariable("Path", "$($env:Path);$installPath\cmd;$installPath\bin", [EnvironmentVariableTarget]::Machine)
 Remove-Item "$installPath\Git-Installer.exe" -Force

 Write-Output "Git install."
}


function Install-GitRepo {
 param (
     [string]$repoUrl = "https://github.com/atomicals/atomicals-js.git",
     [string]$destination = "C:\atomicals-js"
 )

 git clone $repoUrl $destination
 cd $destination
 npm i -g yarn
 yarn install
 yarn build

 Write-Output "Git clone in $destination and install dependency"
}

# 安装环境函数
function Install-Env {
 param ()
 Install-NodeJS
 Install-Git
 Install-GitRepo

 Write-Output "all env install"
 Set-Location "$([System.IO.Path]::Combine($env:USERPROFILE, 'Desktop'))"
}



# 获取用户输入
$userInput = Read-Host @"
script by oooooyoung11
please select:
1. install pow env
2. create wallet
3. import wallet
5. check all wallet info
6. start mint

"@

# 根据用户输入执行相应操作
switch ($userInput) {
 1 { Install-Env }
 2 { 
     cd "C:\atomicals-js"
     & yarn cli wallet-init
     Set-Location "$([System.IO.Path]::Combine($env:USERPROFILE, 'Desktop'))"
 }
 3 {
     cd "C:\atomicals-js"
     $wif = Read-Host "Input wallet WIF private key "
     $alias = Read-Host "Input wallet alias "
     & yarn cli wallet-import $wif $alias
     Set-Location "$([System.IO.Path]::Combine($env:USERPROFILE, 'Desktop'))"
 }
 4 {
     cd "C:\atomicals-js"
     & yarn cli wallets
     Set-Location "$([System.IO.Path]::Combine($env:USERPROFILE, 'Desktop'))"
 }
 5 {
     cd "C:\atomicals-js"
     $gas = Read-Host "Input mint gas "
     $tick = Read-Host "Input mint arc coin name "
     & yarn cli mint-dft $tick --satsbyte $gas*1.2
     Set-Location "$([System.IO.Path]::Combine($env:USERPROFILE, 'Desktop'))"
 }
 default { Write-Output "invalid select" }
}