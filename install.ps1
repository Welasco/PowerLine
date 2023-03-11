# Download Windows CacadiaCode Font
$releases = Invoke-RestMethod -Uri https://api.github.com/repos/ryanoasis/nerd-fonts/releases
$cascadia_release = ($releases[0].assets | Where{$_.Name -eq "CascadiaCode.zip"}).browser_download_url
$font_url = $cascadia_release
$fontfilzip = $font_url.Split("/")[$font_url.Split("/").count-1]
Invoke-WebRequest -Uri $font_url -OutFile $fontfilzip
$RunPath = (Get-Location).path
Expand-Archive "$RunPath\$fontfilzip" -DestinationPath "$RunPath\fonts" -Force

# Function to Install Fonts
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

# Install Fonts
foreach ($f in $(Get-ChildItem "$RunPath\fonts" -Filter *.otf -File)) {
    Install-Fonts -FontFile $f.fullName
    $f.fullname
}

# Installing oh-my-posh from MS Store
winget install XP8K0HKJFRXGCK --accept-package-agreements

# Install Terminal-Icons
Install-Module -Name Terminal-Icons -Repository PSGallery -Force -SkipPublisherCheck

# PowerShell Core
# Install-Module -Name PSReadLine -Scope CurrentUser -Force -SkipPublisherCheck

# Download my personal oh-my-posh config
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Welasco/PowerLine/master/.custom.omp.json" -OutFile "$env:USERPROFILE\.custom.omp.json"

$ProfilePoshGit = @"
Function Load-PowerLine{
    oh-my-posh init pwsh --config ~/.custom.omp.json | Invoke-Expression
    Import-Module -Name Terminal-Icons
}
Load-PowerLine
"@

$ProfilePoshGit | Out-File "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
$ProfilePoshGit | Out-File "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"

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

$fontName = "CaskaydiaCove Nerd Font"

$vscodeSettingsFile = "$env:USERPROFILE\AppData\Roaming\Code\User\settings.json"
Copy-Item $vscodeSettingsFile "$vscodeSettingsFile.bkp"
$rawfile = Get-Content $vscodeSettingsFile -Raw
$jsonfile = $rawfile | ConvertFrom-Json
$jsonfile

#$jsonfile | Add-Member -TypeName System.Management.Automation.PSCustomObject -Name "terminal.integrated.profiles.windows" -MemberType NoteProperty -Value $memobj.'terminal.integrated.profiles.windows' -Force
$jsonfile | Add-Member -Name "terminal.integrated.fontFamily" -MemberType NoteProperty -Value $fontName -Force
$jsonfile | ConvertTo-Json -Depth 100 | Out-File $vscodeSettingsFile


$wtSettingsFile = "$env:USERPROFILE\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
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
$jsonWTfile.profiles.defaults.font | Add-Member -Name "face" -MemberType NoteProperty -Value $fontName -Force
$jsonWTfile | ConvertTo-Json -Depth 100 | Out-File $wtSettingsFile
