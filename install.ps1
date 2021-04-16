# Download Windows CacadiaCode Font
$releases = Invoke-RestMethod -Uri https://api.github.com/repos/microsoft/cascadia-code/releases
#$font_url = "https://github.com/microsoft/cascadia-code/releases/download/v2102.25/CascadiaCode-2102.25.zip"
$font_url = $releases[0].assets[0].browser_download_url
$fontfilzip = $font_url.Split("/")[$font_url.Split("/").count-1]
Invoke-WebRequest -Uri $font_url -OutFile $fontfilzip
$RunPath = (Get-Location).path
#Expand-Archive "$PSScriptRoot\$fontfilzip" -DestinationPath "$PSScriptRoot\fonts" -Force
Expand-Archive "$RunPath\$fontfilzip" -DestinationPath "$RunPath\fonts" -Force

function Install-Fonts {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FontFile
    )
    try {
        $font = $fontFile | split-path -Leaf
        If (!(Test-Path "c:\windows\fonts\$($font)")) {
            switch (($font -split "\.")[-1]) {
                "TTF" {
                    $fn = "$(($font -split "\.")[0]) (TrueType)"
                    break
                }
                "OTF" {
                    $fn = "$(($font -split "\.")[0]) (OpenType)"
                    break
                }
            }
            Copy-Item -Path $fontFile -Destination "C:\Windows\Fonts\$font" -Force
            New-ItemProperty -Name $fn -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts" -PropertyType string -Value $font
        }
    }
    catch {
        write-warning $_.exception.message
    }
}

foreach ($f in $(Get-ChildItem "$RunPath\fonts\ttf" -File)) {
    Install-Fonts -FontFile $f.fullName
    $f.fullname
}    

Install-Module posh-git -Scope CurrentUser
Install-Module oh-my-posh -Scope CurrentUser

# PowerShell Core
# Install-Module -Name PSReadLine -Scope CurrentUser -Force -SkipPublisherCheck

$ProfilePoshGit = @"
Function Load-PowerLine{
    Import-Module posh-git
    Import-Module oh-my-posh
    Set-PoshPrompt -Theme paradox
}

Load-PowerLine
"@

$ProfilePoshGit | Out-File "$env:USERPROFILE\Documents\WindowsPowerShell\Profile-PoshGit.ps1"
$ProfilePoshGit | Out-File "$env:USERPROFILE\Documents\PowerShell\Profile-PoshGit.ps1"

$addmember =@"
{
"terminal.integrated.profiles.windows": {
    "PowerShell PowerLine": {
      "source": "PowerShell",
      "args": ["-NoProfile","-noexit","-command","invoke-expression '. ''C:/Users/$env:USERNAME/Documents/WindowsPowerShell/Profile-PoshGit.ps1'''"]
    }
  }
}
"@

$memobj = $addmember.ToString() | ConvertFrom-Json
#$memobj.'terminal.integrated.profiles.windows'.'PowerShell PowerLine'.args[$memobj.'terminal.integrated.profiles.windows'.'PowerShell PowerLine'.args.count-1] = $memobj.'terminal.integrated.profiles.windows'.'PowerShell PowerLine'.args[$memobj.'terminal.integrated.profiles.windows'.'PowerShell PowerLine'.args.count-1].replace('user',$env:USERNAME)


$vscodeSettingsFile = "$env:USERPROFILE\AppData\Roaming\Code\User\settings.json"
Copy-Item $vscodeSettingsFile "$vscodeSettingsFile.bkp"
#Copy-Item "$vscodeSettingsFile.bkp" $vscodeSettingsFile
$rawfile = Get-Content $vscodeSettingsFile -Raw
$jsonfile = $rawfile | ConvertFrom-Json
$jsonfile

$jsonfile | Add-Member -TypeName System.Management.Automation.PSCustomObject -Name "terminal.integrated.profiles.windows" -MemberType NoteProperty -Value $memobj.'terminal.integrated.profiles.windows' -Force
$jsonfile | Add-Member -Name "terminal.integrated.fontFamily" -MemberType NoteProperty -Value "Cascadia Code PL"
$jsonfile | ConvertTo-Json -Depth 100 | Out-File $vscodeSettingsFile


$wtSettingsFile = "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
Copy-Item $wtSettingsFile "$wtSettingsFile.bkp"
#Copy-Item "$wtSettingsFile.bkp" $wtSettingsFile 
$rawWTfile = Get-Content $wtSettingsFile -Raw
$jsonWTfile = $rawWTfile | ConvertFrom-Json
$jsonWTfile.profiles.list

foreach ($item in $jsonWTfile.profiles.list) {
    if ($item.name -eq "Windows PowerShell") {
        $item | Add-Member -Name "commandline" -MemberType NoteProperty -Value "powershell.exe -noprofile -noexit -command `"invoke-expression '. ''C:/Users/$env:USERNAME/Documents/WindowsPowerShell/Profile-PoshGit.ps1''' `"" -Force
    }
    if ($item.name -eq "PowerShell") {
        $item | Add-Member -Name "commandline" -MemberType NoteProperty -Value "pwsh.exe -noprofile -noexit -command `"invoke-expression '. ''C:/Users/$env:USERNAME/Documents/PowerShell/Profile-PoshGit.ps1''' `"" -Force
    }    
}
$jsonWTfile.profiles.defaults | Add-Member -Name "fontFace" -MemberType NoteProperty -Value "Cascadia Code PL" -Force
$jsonWTfile | ConvertTo-Json -Depth 100 | Out-File $wtSettingsFile
