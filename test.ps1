#if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-ExecutionPolicy Unrestricted -File `"$PSCommandPath`"" -Verb RunAs; exit }
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-ExecutionPolicy Unrestricted -c `"iex (iwr https://raw.githubusercontent.com/Welasco/PowerLine/master/test.ps1)`" " -Verb RunAs; exit }
Get-ChildItem c:\
Read-Host