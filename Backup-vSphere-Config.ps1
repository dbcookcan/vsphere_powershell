#!/bin/pwsh
param([string]$VIServer="",[string]$VIUsername="",[int]$DEBUG,[int]$EMAIL)
@"
===============================================================================
Title       : Backup-vSPhere-Config.ps1
Description : Backup the vSphere configuration from a host.
            :
            : Backs up the vSphere configurations to a local store held
            : in $BackupBaseDir + $Backup_Location
            :
            : Optional capability to push the backups to an AWS S3 bucket.
            :
            : If Powershell is not available, alternately you can create these
            : backups directly on an esxi host via ssh with:
            : Backup:
            : # vim-cmd hostsvc/firmware/backup_config
            : Restore:
            : # vim-cmd hostsvc/firmware/restore_config /tmp/configBundle.tgz
            :
Usage       : .\Backup-vSphere-Config.ps1 or Powershell IDE
Date        : 21/02/2016
AUTHOR      : David Cook
REQUIRES    : VMware PowerCLI
            : s3cmd
            :
CHEATS      : Backup syntax
            : Get-VMHostFirmware -VMHost 10.10.8.22 -BackupConfiguration `
            :     -DestinationPath C:\Users\ewwhite\Downloads
            :
            : Restore syntax
            : Set-VMHostFirmware -VMHost 10.10.8.22 -Restore `
            :     -SourcePath c:\Users\ewwhite\configBundle-10.10.8.22.tgz `
            :     -HostUser root -HostPassword YoMama!!
            :
AWS Policy  : The AWS IAM user should have a policy attached that severely
            : restricts access to only this bucket.
            : example policy
            :  {
            :   "Version":"2018-10-19",
            :   "Statement":[
            :      {
            :         "Effect":"Allow",
            :         "Action":[
            :            "s3:PutObject",
            :            "s3:GetObject",
            :            "s3:GetObjectVersion",
            :            "s3:DeleteObject",
            :            "s3:DeleteObjectVersion"
            :         ],
            :         "Resource":"arn:aws:s3:::examplebucket/*"
            :      }
            :   ]
            :  }
            :
===============================================================================
History
Ver     Date            Who     Details
v1.00   21/02/2016      dbc     Initial delivery

===============================================================================
"@

# Set local vars
$VER=1.01
$ReportName = "Backup vSphere Configuration"
$ScriptName = $MyInvocation.MyCommand.Definition
IF ($EMAIL -gt 1){ $EMAIL = 1 }
$emailfrom="david.cook@kirasystems.com"
$emailto="david.cook@kirasystems.com"


#
# Include Kira common header
. "./Kira_Include.ps1"

# Set local vars here which are dependant/subordinate to vars or calculations
# performed in the common header.
# Backup location underneath $BackupBaseDir from the include file.
$Backup_Location="/VMware/$filedate/"
$S3_LOC="s3://dbc-tbucket-2020-01-30/Backups"

#
# Connect to Virtual Center
$VC = Connect-VIServer -Server $VIServer -Port $port -user $VIUsername `
       -password $VIpassword -ErrorAction SilentlyContinue

If (!$?) {

  #
  # Error - failed to connect to the virtual center server
  Write-Host "ERROR: Failed to connect to Virtual Center: $VCHostName"

} Else {

  #
  # Successful login to Virtualcenter ... yay!


  # Build the target directory path and check if it exists. If not,
  # create it.
  $targetdir = $BackupBaseDir+$Backup_Location
  If ((Test-Path -PathType Container -Path $targetdir) -eq $false){
     # Create the directory that doesn't exist
     $rc=New-Item -ItemType Directory -Force -Path $targetdir
  } # ENDIF : check target directory


  #
  # Get list of ESXi hosts
  $hostlist = Get-VMHost

  ForEach ($vmhost in $hostlist) {
    Write-Host ("`nESXi Host: "+$vmhost)

    # Check if the vmhost is in the connected state
    # ie: not in maintenance mode or not in error state
    If(($vmhost.ConnectionState) -ne 0){

       Write-Host "Host "$vmhost.name" is not connected"
    } else {

      #
      # Backup the host configuration
      $rc=Get-VMHostFirmware -VMHost $vmhost -BackupConfiguration `
           -DestinationPath $targetdir
      Write-Host "Backup host $vmhost"
      Write-Host "  Dir  : "$rc.Data.directoryname
      Write-Host "  File : "$rc.Data.Name
      Write-Host "  Size : "$rc.Data.Length
      Write-Host ""
    } # ENDIF : host connect/backup

  } # ENDIF : ESXi host loop

  #
  # Disconnect from Virtualcenter
  Disconnect-VIServer -Confirm:$False
}

#
# Copy Backups to S3 for off-site archive
iex "aws s3 cp $targetdir $S3_LOC$Backup_Location --recursive"

# END OF SCRIPT
Write-Host "`nEnd of script ...."

# END OF SCRIPTS
