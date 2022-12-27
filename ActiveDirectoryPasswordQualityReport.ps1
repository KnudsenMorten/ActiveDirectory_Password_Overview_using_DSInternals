#Requires -Version 5.0
<#
    .SYNOPSIS
    This script will do a DCSync (replication of Directory) of your Active Directory to retrieve the password hash keys of all accounts (part of scope)
    The data will be expoerted into several files for further analysis.

    .NOTES
    VERSION: 2212

    .COPYRIGHT
    @mortenknudsendk on Twitter
    Blog: https://mortenknudsen.net
    
    .LICENSE
    Licensed under the MIT license.

    .WARRANTY
    Use at your own risk, no warranty given!
#>

#--------------------------------------------------------
# PS Modules
#--------------------------------------------------------

# TLS 1.2 must be enabled on older versions of Windows.
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# Download the NuGet package manager binary.
Install-PackageProvider -Name NuGet -Force

# Register the PowerShell Gallery as package repository if it is missing for any reason.
if($null -eq (Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue)) { Register-PSRepository -Default }

# Download the DSInternals PowerShell module.
Install-Module -Name DSInternals -Force


#--------------------------------------------------------
# Variables
#--------------------------------------------------------

# This is the location where your password dictionary file exists. You can start by creating a simple file with one line like Password1234
$Passwords = "D:\SCRIPTS\DATA\AD-DictionaryPasswords.txt"


#------------------------------------------------------------------------------------------------------------
# MAIN PROGRAM
#------------------------------------------------------------------------------------------------------------

$ExportDateTime = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

$OutPutReport_ALL                   = "$($global:PathScripts)\OUTPUT\AD-PasswordQualityReport_ALL_$($ExportDateTime).txt"
$OutPutReport_Enabled_Only_ALL      = "$($global:PathScripts)\OUTPUT\AD-PasswordQualityReport_Enabled_Only_ALL_$($ExportDateTime).txt"
$OutPutReport_Disabled_Only_ALL     = "$($global:PathScripts)\OUTPUT\AD-PasswordQualityReport_Disabled_Only_ALL_$($ExportDateTime).txt"
$OutPutReport_Admins_Only_ALL       = "$($global:PathScripts)\OUTPUT\AD-PasswordQualityReport_Admins_Only_ALL_$($ExportDateTime).txt"

$Result_ALL                         = Get-ADReplAccount -All:$true -Server (Get-ADDomainController).Hostname -NamingContext (Get-ADRootDSE | select *naming*).defaultNamingContext
$Result_Enabled_Only_ALL            = $Result_ALL | Where-Object { ($_.Enabled -eq $true) -and ($_.SamAccountType -eq "User") }
$Result_Disabled_Only_ALL           = $Result_ALL | Where-Object { ($_.Enabled -eq $false) -and ($_.SamAccountType -eq "User")}
$Result_Admins_Only_ALL             = $Result_ALL | Where-Object { ($_.AdminCount -eq $true)  -and ($_.SamAccountType -eq "User")}

$PasswordResult_All                 = $Result_ALL | Test-PasswordQuality -WeakPasswordsFile $Passwords
$PasswordResult_Enabled_Only_ALL    = $Result_Enabled_Only_ALL | Test-PasswordQuality -WeakPasswordsFile $Passwords
$PasswordResult_Disabled_Only_ALL   = $Result_Disabled_Only_ALL | Test-PasswordQuality -WeakPasswordsFile $Passwords
$PasswordResult_Admins_Only_ALL     = $Result_Admins_Only_ALL | Test-PasswordQuality -WeakPasswordsFile $Passwords

Write-Output "Building reports ...."
$PasswordResult_All | Out-File -FilePath $OutPutReport_ALL -Encoding UTF8
$PasswordResult_Enabled_Only_ALL | Out-File -FilePath $OutPutReport_Enabled_Only_ALL -Encoding UTF8
$PasswordResult_Disabled_Only_ALL | Out-File -FilePath $OutPutReport_Disabled_Only_ALL -Encoding UTF8
$PasswordResult_Admins_Only_ALL | Out-File -FilePath $OutPutReport_Admins_Only_ALL -Encoding UTF8
