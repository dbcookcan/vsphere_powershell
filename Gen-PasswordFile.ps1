param([string]$VIServer="",[string]$user="")
@"
===============================================================================
Title       : Gen-Password.ps1
Description : Generate an encrypted password for a user based on the master
            : key value and the text password from authentication source which
            : will be used for the platform.

            : WHEN YOU WANT TO CHANGE PASSWORDS
            : 1. Change the password on your authenticator as normal.
            : 2. Run Gen-Masterfile.ps1 to create a new encryption keyfile which
            :    acts as the salt for the encryption.
            : 3. Run Gen-Password.ps1 to generate a new PowerShell Credential
            :    Store file to authenticate ids used for automation scripts.

Usage       : pwsh Gen-Password.ps1
Date        : 03/21/2019
AUTHOR      : David Cook
REQUIRES    : VMware PowerCLI
===============================================================================
"@

#
# Set vars/defaults
$ReportName = "Generate New Keyfile"
$CredDir = "/opt/automate/CredStore/"
$KeyFileName = "MasterKey.txt"
$KeyFile = $CredDir+$KeyFileName
$DEBUG=0

#
# Print user directions onscreen
Write-Host ""
Write-Host " ******************************************************"
Write-Host " This tool creates a new PowerShell Credential Store"
Write-Host " encrypted password file based on the encryption"
Write-Host " key stored in $FileSpec"
Write-Host ""
Write-Host " When prompted, enter the USERNAME the new password is"
Write-Host " for, followed by the PASSWORD you have previously"
Write-Host " configured in your authentication mechanism."
Write-Host ""
Write-Host " The CredentialStore filename will include the id the"
Write-Host " credential is for. Within automation scripts, you may"
Write-Host " then use this credential store."
Write-Host " ******************************************************"
Write-Host ""


#
# Retrieve the Master Key
$key=Get-Content -Path $KeyFile
if( $DEBUG -gt 0 ){ Write-Host "Key: $key" }

# Get Server/User/Password info from user
if( [string]::IsNullOrEmpty($VIServer) ){
  if( $DEBUG -gt 0 ){
     Write-Host "No server on command line, interactive prompting"
  }
  $VIServer = Read-Host "Please enter the SERVER name "
}

if( [string]::IsNullOrEmpty($user) ){
  if( $DEBUG -gt 0 ){
     Write-Host "No username on command line, interactive prompting"
  }
  $user = Read-Host "Please enter the USERNAME "
}
$mypass = Read-Host "Please enter the PASSWORD " -AsSecureString


#
# Generate Credential Store filename
$PasswordFile=$CredDir+$VIServer+"-"+$user+".cred"


#
# CREATING SECURE CREDENTIALS
# Encrypt Secure String with key and store in external file
ConvertFrom-SecureString -key $key -SecureString $mypass | `
  Out-File $PasswordFile
Write-Host "Encrypted Password File: $PasswordFile"

#
# RETRIEVING SECURE CREDENTIALS FOR USE
# Retrieve encrypted credential then store as PSCredential object                
$MyCreds = New-Object -TypeName System.Management.Automation.PSCredential `
                 -ArgumentList $user, (Get-Content $PasswordFile | `
                 ConvertTo-SecureString -Key $key)

# Display my object
$MyCreds.GetType()

# Print out the decoded password
if ( $DEEBUG -gt 0 ){
   $Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($MyCreds.password)
   $result = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr)
   Write-Host "Password: "$result
}

# END OF SCRIPT

