@"
===============================================================================
Title       : Advan_Include.ps1
Description : Standard Advantech header file for Powershell.
            :
            : Called as a "sourced" file at the top to provide features
            : from a common library.

Usage       : To be included in other scripts with:
                        . "./Advan_Include.ps1"
Date        : 21/03/2019
AUTHOR      : David Cook
REQUIRES    : VMware PowerCLI
===============================================================================
History
Ver     Date            Who     Details
v1.00   21/03/2019      dbc     Initial delivery
v1.01   17/04/2019      dbc     Added in-app declarations if not defined
                                elsewhere.
				Add credential store support.
v1.02	01/12/2020	dbc	Modified for PowerShell Core 7.
===============================================================================
"@

#
# Set common vars across all instances
$port="443"
$OutputBaseDir = "/opt/automate/Reports"
$BackupBaseDir = "/opt/automate/Backups"
$filedate = Get-Date -format yyyy.M.d
$CredDir = "/opt/automate/CredStore/"
$KeyfileName = "MasterKey.txt"
$KeyFile = $CredDir+$KeyfileName
$tab=[char]9

# Set typical vars used within applications if they have not previously been
# declared elsewhere
If (!$DEBUG) { $DEBUG=0 }
If (!$ERRTOT) { $ERRTOT=0 }


#
# Retrieve the Master Key file from common store. This is a 192-bit encryption
# key that was generated with the gen-keyfile.ps1 program. It forms the salt
# for all encryption of credential stores.
$key=Get-Content -Path $KeyFile
if( $DEBUG -gt 0 ){ Write-Host "Key: $key" }

#
# If no command line parms were provided we will interactively get the
# credential
# information the user.
if( [string]::IsNullOrEmpty($VIServer) ){
    if( $DEBUG -gt 0 ){ 
      Write-Host "No VIServer on command line, interactive prompting"
    }
    $VIServer = read-host "$ReportName`n`nVirtualCenter or ESXI Host Name"
} # END If Server string empty
if( [string]::IsNullOrEmpty($VIUsername) ){
    if( $DEBUG -gt 0 ){
       Write-Host "No VIUser on command line, interactive prompting"
    }
    $VIUsername = read-host "$ReportName`n`nUsername for "$VIServer
} # END: If Username string is empty


#
# Generate Credential Store filename
$CredFile=$CredDir+$VIServer+"-"+$VIUsername+".cred"
if( $DEBUG -gt 0 ){ Write-Host "Credential File: $CredFile" }


#
# If credential file exists, we read it in and associate them with the
#  user/password
# variables.
If (Test-Path $CredFile) {
   # Credential File exists
   # Read them back

   #
   # Retrieve encrypted credential and store as PSCredential object
   $MyCreds = New-Object -TypeName System.Management.Automation.PSCredential `
                 -ArgumentList $VIUsername, (Get-Content $CredFile | `
                 ConvertTo-SecureString -Key $key)

   #
   # Assign PSCredential object back to local vars because login parameters
   # are different depending on how they were obtained. Local vars becomes
   # lowest-common-denominator
   $VISecurePassword=$MyCreds.Password
   $VIPassword = (New-Object PSCredential "$VIUsername",$VISecurePassword).GetNetworkCredential().Password

   # Clear credential store
   $MyCreds=""

} else {

   #
   # No credential file, have to get info from user
   if( $DEBUG -gt 0 ){ Write-Host "Credential File does not exist. Prompt user" }

   # Get info from user interactively
   $VISecurePassword = read-host -assecurestring "$ReportName`n`nPassword"
   $VIPassword = (New-Object PSCredential "$VIUsername",$VISecurePassword).GetNetworkCredential().Password

} # END: Test Credential file exist


# END OF SCRIPT
