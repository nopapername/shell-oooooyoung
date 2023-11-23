
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
     [string]$repoUrl = "https://github.com/IErcOrg/ierc-miner-js",
     [string]$destination = "C:\ierc-miner-js"
 )

 git clone $repoUrl $destination
 cd $destination
 npm i -g yarn
 npm install

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
4. check wallet info
5. check all wallet info
6. start mint

"@

# 根据用户输入执行相应操作
switch ($userInput) {
 1 { Install-Env }
 2 { 
     cd "C:\ierc-miner-js"
     & yarn run cli wallet --create
     Set-Location "$([System.IO.Path]::Combine($env:USERPROFILE, 'Desktop'))"
 }
 3 {
     cd "C:\ierc-miner-js"
     $privateKey = Read-Host "Input wallet private key "
     & yarn run cli wallet --set $privateKey
     Set-Location "$([System.IO.Path]::Combine($env:USERPROFILE, 'Desktop'))"
 }
 4 {
     cd "C:\ierc-miner-js"
     $address = Read-Host "Input wallet address "
     & yarn run cli wallet show $address
     Set-Location "$([System.IO.Path]::Combine($env:USERPROFILE, 'Desktop'))"
 }
 5 {
     cd "C:\ierc-miner-js"
     & yarn run cli wallet --all
     Set-Location "$([System.IO.Path]::Combine($env:USERPROFILE, 'Desktop'))"
 }
 6 {
     cd "C:\ierc-miner-js"
     $address = Read-Host "Input wallet address "
     $tick = Read-Host "Input mint pow ierc name "
     & yarn run cli mine $tick --account $address
     Set-Location "$([System.IO.Path]::Combine($env:USERPROFILE, 'Desktop'))"
 }
 default { Write-Output "invalid select" }
}
