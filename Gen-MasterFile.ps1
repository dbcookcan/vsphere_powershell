@"
===============================================================================
Title       : Gen-MasterFile.ps1
Description : Generate a master key for encryption of passwords. To be used
            : as the salt for a series of passwords for automation scripts.
            : To change all passwords, re-run Gen-MasterFile.ps1 then
            : recreate new passwords based on the key.
            : Finally, change the passwords in vcenter or your ldap server.

Usage       : pwsh gen-keyfile.ps1
Date        : 03/21/2019
AUTHOR      : David Cook
REQUIRES    : VMware PowerCLI
===============================================================================
History
Ver     Date            Who     Details
v1.00   03/21/2019      dbc     Initial delivery
===============================================================================
"@

#
# Set vars/defaults
$ReportName = "Generate New Keyfile"
$CredDir = "/opt/automate/.CredStore/"
$Keyfile = "MasterKey.txt"
$KeyFile = $CredDir+$Keyfile

#
# Generate 192 bit key
# Create list of 24 random numbers to be used as the salt value for encrypting
# keyfile for vcenter automations.
$key = New-Object Byte[] 24
for($i=0; $i -lt 24; $i++)
{
  $key[$i] = (Get-Random -Minimum 0 -Maximum 254)
}


#
# Write the new MasterKey file
Set-Content -Path $KeyFile -Value $key
Write-Host "Keyfile: $KeyFile"

Write-Host "This file ($KeyFile) must be moved by root user to /usr/.CredStore"

# END OF SCRIPT

