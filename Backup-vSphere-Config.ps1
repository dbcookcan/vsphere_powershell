#!/bin/pwsh
param([string]$VIServer="",[string]$VIUsername="",[int]$DEBUG,[int]$EMAIL,[int]$SENDAWS)
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

            : Runing in cron as follows:
            : # Backup the VMware vSphere configuration @ 1:00 every day
            : 00 1 * * * /opt/automate/powershell/Prod/Backup-vSphere-Config.ps1 [vcenter FQDN] [admin acct] 0 0 1
            : NOTE1:  MUST USE FULL PATHNAMES FOR CRON ENVIRONMENT.
            : NOTE2:  3rd param (0) is DEBUG
            :         4th param (0) is EMAIL (don't send)
            :         5th param (1) is SENDAWS (yes, send to AWS S3) 
===============================================================================
History
Ver     Date            Who     Details
v1.00   21/02/2016      dbc     Initial delivery
v1.01	03/12/2020	dbc	Add optional params for AWS s3 & fully
                                qualified binary names for use in crontab.
===============================================================================
"@

# Set local vars
$VER=1.01
$ReportName = "Backup vSphere Configuration"
$ScriptName = $MyInvocation.MyCommand.Definition
$S3_LOC="s3://dbc-tbucket-2020-01-30/Backups"
$AWSCLI="/usr/local/bin/aws"
# Do we send email?
IF ($EMAIL -gt 1){ $EMAIL = 1 } else { $EEMAIL = 0 }
$emailfrom="admin@advan.ca"
$emailto="admin@advan.ca"
# Do we send backups to AWS?
IF ($SENDAWS -ge 1){ $SENDAWS = 1 } else { $SENDAWS = 0 }


#
# Include Advantech common header
. "/usr/.CredStore/Advan_Include.ps1"

# Set local vars here which are dependant/subordinate to vars or calculations
# performed in the common header.
# Backup location underneath $BackupBaseDir from the include file.
$Backup_Location="/VMware/$filedate/"

#
# Connect to Virtual Center
$VC = Connect-VIServer -Server $VIServer -Port $port -user $VIUsername `
       -password $VIPassword -ErrorAction SilentlyContinue

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
  Do-Disconnect
}

#
# Copy Backups to S3 for off-site archive
if ( $SENDAWS -eq 1 ) {
   iex "$AWSCLI s3 cp $targetdir $S3_LOC$Backup_Location --recursive"
} # END SENDAWS

# END OF SCRIPT
Write-Host "`nEnd of script ...."

# END OF SCRIPTS
