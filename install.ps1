# Re-Execute the script in admin mode in case it's not already
# Required to install windows fonts
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process pwsh.exe "-ExecutionPolicy Unrestricted -c `"iex (iwr https://raw.githubusercontent.com/Welasco/PowerLine/master/install.ps1)`" " -Verb RunAs; exit }

###############################################
# Download Windows CascadiaCode Font
###############################################
$releases = Invoke-RestMethod -Uri https://api.github.com/repos/ryanoasis/nerd-fonts/releases
$cascadia_release = ($releases[0].assets | Where{$_.Name -eq "CascadiaCode.zip"}).browser_download_url
$font_url = $cascadia_release
$fontfilzip = $font_url.Split("/")[$font_url.Split("/").count-1]
Invoke-WebRequest -Uri $font_url -OutFile $fontfilzip
$RunPath = (Get-Location).path
Expand-Archive "$RunPath\$fontfilzip" -DestinationPath "$RunPath\fonts" -Force
###############################################

###############################################
# Function to Install Fonts
###############################################
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
###############################################

###############################################
# Install Fonts
###############################################
foreach ($f in $(Get-ChildItem "$RunPath\fonts" -Filter *.otf -File)) {
    Install-Fonts -FontFile $f.fullName
    $f.fullname
}
###############################################

###############################################
# Installing oh-my-posh from MS Store
###############################################
winget install XP8K0HKJFRXGCK --accept-package-agreements --accept-source-agreements
###############################################

###############################################
# Install Terminal-Icons
###############################################
Install-Module -Name Terminal-Icons -Repository PSGallery -Force -SkipPublisherCheck
###############################################

###############################################
# PowerShell Core
###############################################
# Install-Module -Name PSReadLine -Scope CurrentUser -Force -SkipPublisherCheck
###############################################

###############################################
# Download my personal oh-my-posh config
###############################################
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Welasco/PowerLine/master/.custom.omp.json" -OutFile "$env:USERPROFILE\.custom.omp.json"
###############################################

###############################################
# Defining Profile PowerShell7
###############################################
$ProfilePoshGit = @"
Function Load-PowerLine{
    oh-my-posh init pwsh --config ~/.custom.omp.json | Invoke-Expression
    Import-Module -Name Terminal-Icons
}
Load-PowerLine
"@

# Create Profile PowerShell7
if (!(Test-Path $PROFILE)) {
    New-Item $PROFILE -Force
}
$ProfilePoshGit | Out-File $PROFILE -Append
###############################################

###############################################
# Create Profile PowerShell 5
###############################################
$scriptblock = {
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted;
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    Set-PSRepository PSGallery -InstallationPolicy Trusted
    Install-Module -Name Terminal-Icons -Repository PSGallery -Force -SkipPublisherCheck;
    if(!(Test-Path $PROFILE)){New-Item $PROFILE -Force};
$ProfilePoshGit = @"
Function Load-PowerLine{
    oh-my-posh init pwsh --config ~/.custom.omp.json | Invoke-Expression
    Import-Module -Name Terminal-Icons
}
Load-PowerLine
"@
    Write-Output "PowerShell 5 Profile: $PROFILE"
    $ProfilePoshGit | Out-File $PROFILE -Append;
}
powershell -ExecutionPolicy Unrestricted $scriptblock
###############################################

# Code for reference
# $addmember =@"
# {
# "terminal.integrated.profiles.windows": {
#     "PowerShell PowerLine": {
#       "source": "PowerShell",
#       "args": ["-NoProfile","-noexit","-command","invoke-expression '. ''C:/Users/$env:USERNAME/Documents/WindowsPowerShell/Profile-PoshGit.ps1'''"]
#     }
#   }
# }
# "@
# $memobj = $addmember.ToString() | ConvertFrom-Json
# $memobj.'terminal.integrated.profiles.windows'.'PowerShell PowerLine'.args[$memobj.'terminal.integrated.profiles.windows'.'PowerShell PowerLine'.args.count-1] = $memobj.'terminal.integrated.profiles.windows'.'PowerShell PowerLine'.args[$memobj.'terminal.integrated.profiles.windows'.'PowerShell PowerLine'.args.count-1].replace('user',$env:USERNAME)

# CaskaydiaCove Nerd Font variable
$fontName = "CaskaydiaCove Nerd Font"

###############################################
# Updating default font for VSCode if installed
###############################################
$vscodeSettingsFile = "$env:USERPROFILE\AppData\Roaming\Code\User\settings.json"
if (Test-Path $vscodeSettingsFile) {
    Copy-Item $vscodeSettingsFile "$vscodeSettingsFile.bkp"
    $rawfile = Get-Content $vscodeSettingsFile -Raw
    $jsonfile = $rawfile | ConvertFrom-Json
    $jsonfile

    #$jsonfile | Add-Member -TypeName System.Management.Automation.PSCustomObject -Name "terminal.integrated.profiles.windows" -MemberType NoteProperty -Value $memobj.'terminal.integrated.profiles.windows' -Force
    $jsonfile | Add-Member -Name "terminal.integrated.fontFamily" -MemberType NoteProperty -Value $fontName -Force
    $jsonfile | ConvertTo-Json -Depth 100 | Out-File $vscodeSettingsFile
}
###############################################

###############################################
# Updating default font for Windows Terminal if installed
###############################################
$wtSettingsFile = "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if (Test-Path $vscodeSettingsFile) {
    Copy-Item $wtSettingsFile "$wtSettingsFile.bkp"
    $rawWTfile = Get-Content $wtSettingsFile -Raw
    $jsonWTfile = $rawWTfile | ConvertFrom-Json
    $jsonWTfile.profiles.list
    # foreach ($item in $jsonWTfile.profiles.list) {
    #     if ($item.name -eq "Windows PowerShell") {
    #         $item | Add-Member -Name "commandline" -MemberType NoteProperty -Value "powershell.exe -noprofile -noexit -command `"invoke-expression '. ''C:/Users/$env:USERNAME/Documents/WindowsPowerShell/Profile-PoshGit.ps1''' `"" -Force
    #     }
    #     if ($item.name -eq "PowerShell") {
    #         $item | Add-Member -Name "commandline" -MemberType NoteProperty -Value "pwsh.exe -noprofile -noexit -command `"invoke-expression '. ''C:/Users/$env:USERNAME/Documents/PowerShell/Profile-PoshGit.ps1''' `"" -Force
    #     }
    # }

    $Caskaydia_font = [PSCustomObject]@{
        face = $fontName
    }
    $jsonWTfile.profiles.defaults | Add-Member -Name "font" -MemberType NoteProperty -Value $Caskaydia_font -Force
    $jsonWTfile.profiles.defaults.font | Add-Member -Name "face" -MemberType NoteProperty -Value $fontName -Force
    $jsonWTfile | ConvertTo-Json -Depth 100 | Out-File $wtSettingsFile
}
###############################################

###############################################
# Allow F8 to execute selected lines
###############################################
#$keybindings = '
#// Place your key bindings in this file to override the defaultsauto[]
#[
#    {
#        "key": "f8",
#        "command": "workbench.action.terminal.runSelectedText"
#    }
#]
#'
#$keybindings | Out-File "$env:APPDATA\Code\User\keybindings.json" -Encoding utf8

Read-Host "Press Enter to close this window"
exit
