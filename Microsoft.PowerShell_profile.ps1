#$Cred=Get-Credential
#$Cred.Password | ConvertFrom-SecureString | Set-Content "C:\Users\vsantana\Documents\WindowsPowershell\Hepoca-Connention-Password.sec"
#$Cred.Password | ConvertFrom-SecureString | Set-Content "C:\Users\vsantana\Documents\WindowsPowershell\VWSHyper-V-Password.sec"
Function Connect-VWSHyperV{
    $username = "administrator"
    $password = Get-Content "C:\Users\vsantana\OneDrive - Microsoft\Documents\PowerShell\VWSHyper-V-Password.sec" | convertto-securestring
    $global:VWSCredential = new-object -typename System.Management.Automation.PSCredential -argumentlist $username,$password

    #Import-PSSession (New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Authentication Basic -Credential $Credential -SessionOption (New-PSSessionOption -SkipRevocationCheck -SkipCACheck -SkipCNCheck)  -AllowRedirection)
    $sess = New-PSSession -Credential $VWSCredential -ComputerName vwshyper-v.localdomain
    Enter-PSSession $sess
    $host.ui.RawUI.WindowTitle = "Connected to: VWSHyperV"
}

Function WakeUp-VWSHyperV{
    $Mac = "a0:2b:b8:40:f0:1c"
    $MacByteArray = $Mac -split "[:-]" | ForEach-Object { [Byte] "0x$_"}
    [Byte[]] $MagicPacket = (,0xFF * 6) + ($MacByteArray  * 16)
    $UdpClient = New-Object System.Net.Sockets.UdpClient
    $UdpClient.Connect(([System.Net.IPAddress]::Broadcast),7)
    $UdpClient.Send($MagicPacket,$MagicPacket.Length)
    $UdpClient.Close()
}

Function Sleep-VWSHyperV{
    $username = "administrator"
    $password = Get-Content "C:\Users\vsantana\OneDrive - Microsoft\Documents\PowerShell\VWSHyper-V-Password.sec" | convertto-securestring
    $global:VWSCredential = new-object -typename System.Management.Automation.PSCredential -argumentlist $username,$password

    $global:VWSJob = Invoke-Command -ComputerName vwshyper-v.localdomain -Credential $VWSCredential -ScriptBlock {C:\sleep.bat} -AsJob
    #Invoke-Command -ComputerName vwshyper-v.localdomain -Credential $VWSCredential -ScriptBlock {C:\sleep.bat}
    # $host.ui.RawUI.WindowTitle = "Connected to: VWSHyperV"
}

Function Enable-AzVMAccess{
    param (
        [Parameter(Mandatory=$true)]
        $ResourceGroupName,
        [Parameter(Mandatory=$true)]
        [Alias("VM","VMName")]
        $Name,
        [Parameter(Mandatory=$true)]
        [ValidateSet("Linux","Windows")]
        $OS
    )
    if ($OS -eq "Linux") {
        az vm open-port `
        --resource-group $ResourceGroupName `
        --name $Name `
        --port '2222'

        az vm run-command invoke `
          --resource-group $ResourceGroupName `
          --name $Name `
          --command-id RunShellScript `
          --scripts "sed -i 's/#Port 22/Port 2222/g' /etc/ssh/sshd_config; systemctl restart sshd"
    }
    if ($OS -eq "Windows") {
        az vm open-port `
        --resource-group $ResourceGroupName `
        --name $Name `
        --port '33389'

        az vm run-command invoke `
          --resource-group $ResourceGroupName `
          --name $Name `
          --command-id SetRDPPort `
          --parameters 'RDPPORT=33389'
    }
}

###
# Az CLI auto-complete
Register-ArgumentCompleter -Native -CommandName az -ScriptBlock {
    param($commandName, $wordToComplete, $cursorPosition)
    $completion_file = New-TemporaryFile
    $env:ARGCOMPLETE_USE_TEMPFILES = 1
    $env:_ARGCOMPLETE_STDOUT_FILENAME = $completion_file
    $env:COMP_LINE = $wordToComplete
    $env:COMP_POINT = $cursorPosition
    $env:_ARGCOMPLETE = 1
    $env:_ARGCOMPLETE_SUPPRESS_SPACE = 0
    $env:_ARGCOMPLETE_IFS = "`n"
    $env:_ARGCOMPLETE_SHELL = 'powershell'
    az 2>&1 | Out-Null
    Get-Content $completion_file | Sort-Object | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, "ParameterValue", $_)
    }
    Remove-Item $completion_file, Env:\_ARGCOMPLETE_STDOUT_FILENAME, Env:\ARGCOMPLETE_USE_TEMPFILES, Env:\COMP_LINE, Env:\COMP_POINT, Env:\_ARGCOMPLETE, Env:\_ARGCOMPLETE_SUPPRESS_SPACE, Env:\_ARGCOMPLETE_IFS, Env:\_ARGCOMPLETE_SHELL
}
###

Function Load-PowerLine{
    oh-my-posh init pwsh --config ~/.custom.omp.json | Invoke-Expression
    Import-Module -Name Terminal-Icons
}
Load-PowerLine

if([string]::IsNullOrEmpty((Get-Alias k -ErrorAction SilentlyContinue))){
    New-Alias -Name k -Value kubectl
}

kubectl completion powershell | Out-String | Invoke-Expression
(kubectl completion powershell | Out-String).Replace("-CommandName 'kubectl'","-CommandName 'k'") | Invoke-Expression
#helm completion powershell | Out-String | Invoke-Expression
oc completion powershell | Out-String | Invoke-Expression
