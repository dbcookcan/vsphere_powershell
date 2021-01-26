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
$SharedCredDir = "/usr/.CredStore/"
$CredDir = "$HOME/.CredStore/"
$KeyfileName = "MasterKey.txt"
$KeyFile = $SharedCredDir+$KeyfileName
$tab=[char]9
$MyName = $MyInvocation.MyCommand.Definition

# Set typical vars used within applications if they have not previously been
# declared elsewhere
If (!$DEBUG) { $DEBUG=0 }
If (!$ERRTOT) { $ERRTOT=0 }

#
# Common functions
function Do-Disconnect {
  Disconnect-VIServer -Confirm:$False
}

#
# Check existence & permissions on the shared credential store & include
# library locations
If (Test-Path $SharedCredDir){
   $perms=stat -c '%a' $SharedCredDir
   If ($perms -ne 555){
      Write-Host "Must have 555 permissions on $SharedCredDir. Exiting..."
      exit 9
   }
}Else{
   Write-Host "Credstore $SharedCredStore does not exist."
   exit 9
}


#
# Now check the user local credential store and create it if missing.
# library locations
If (Test-Path $CredDir){
   $perms=stat -c '%a' $CredDir
   If ($perms -ne 700){
      Write-Host "Must have 700 permissions on $CredDir. Exiting..."
      exit 9
   }
}Else{
   Write-Host "Local store: $CredDir"
   mkdir $CredDir
   chmod 0700 $CredDir
}

# Check the permissions on the Master file.
$perms=stat -c '%a' $KeyFile
If ($perms -ne 644){
   Write-Host "$KeyFile permissions not 644. Exiting...."
   exit 9
}

# Finally, check the permissions on this file are tight enough to prevent
# modifications by users to alter this security check.
If( $DEBUG -gt 0 ){ Write-Host "Include file: $MyName" }
$perms=stat -c '%a' $MyName
If ($perms -ne 644){
   Write-Host "$MyName permissions not 644. Exiting...."
   exit 9
}


#
# Retrieve the Master Key file from common store. This is a 192-bit encryption
# key that was generated with the gen-keyfile.ps1 program. It forms the salt
# for all encryption of credential stores.
$key=Get-Content -Path $KeyFile
If( $DEBUG -gt 0 ){ Write-Host "Key: $key" }

#
# If no command line parms were provided we will interactively get the
# credential
# information the user.
If( [string]::IsNullOrEmpty($VIServer) ){
    If( $DEBUG -gt 0 ){ 
      Write-Host "No VIServer on command line, interactive prompting"
    }
    $VIServer = read-host "$ReportName`n`nVirtualCenter or ESXI Host Name"
} # END If Server string empty
If( [string]::IsNullOrEmpty($VIUsername) ){
    If( $DEBUG -gt 0 ){
       Write-Host "No VIUser on command line, interactive prompting"
    }
    $VIUsername = read-host "$ReportName`n`nUsername for "$VIServer
} # END: If Username string is empty


#
# Generate Credential Store filename
$CredFile=$CredDir+$VIServer+"-"+$VIUsername+".cred"
If( $DEBUG -gt 0 ){ Write-Host "Credential File: $CredFile" }


#
# If credential file exists, we read it in and associate them with the
#  user/password
# variables.
If (Test-Path $CredFile) {
   # Credential File exists
   # Read them back

   #
   # Check to ensure file permissions are not too open.
   $perms=stat -c '%a' $CredFile
   If ($perms -ne 660){
      Write-Host "Must have 660 permissions on $SharedCredDir. Exiting..."
      exit 9
   }

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

} Else {

   #
   # No credential file, have to get info from user
   If( $DEBUG -gt 0 ){ Write-Host "Credential File does not exist. Prompt user" }

   # Get info from user interactively
   $VISecurePassword = read-host -assecurestring "$ReportName`n`nPassword"
   $VIPassword = (New-Object PSCredential "$VIUsername",$VISecurePassword).GetNetworkCredential().Password

} # END: Test Credential file exist


# END OF SCRIPT
