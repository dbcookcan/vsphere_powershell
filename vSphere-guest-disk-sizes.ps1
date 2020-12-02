#!/bin/pwsh
param([string]$VIServer="",[string]$VIUsername="",[int]$DEBUG,[int]$EMAIL)
@"
===============================================================================
NAME    : vSPhere-guest-disk-sizes.ps1
AUTHOR  : David Cook
DATE    : 2013.03.22
COMMENT : Login to vSPhere and identify all guest VM disk sizes
REQUIRES: VMware PowerCLI
===============================================================================
History
Ver     Date            Who     Details
v1.00   21/02/2016      dbc     Initial delivery
===============================================================================
"@
#
#
# Set local vars
$VER=1.01
$ReportName = "vSphere Guest Disk Sizes"


#
# Include Kira common header
. "./Kira_Include.ps1"


#
# Connect to Virtual Center
$VC = Connect-VIServer -Server $VIServer -Port $port -user $VIusername `
       -password $VIpassword -ErrorAction SilentlyContinue

If (!$?) {

  #
  # Error - failed to connect to the virtual center server
  Write-Host "ERROR: Failed to connect to Virtual Center: $VCHostName"

} Else {

  #
  # Successful login to Virtualcenter ... yay!

  #
  # Get list of Datacenters

  ForEach ($VM in Get-VM | Sort-Object) {
    $VM.Extensiondata.Guest.Disk |`
    Select @{N="VM Name      ";E={$VM.Name}},@{N="Disk Path             ";E={$_.DiskPath}},
           @{N="Capacity(MB)";E={[math]::Round($_.Capacity/ 1MB)}},
           @{N="Free Space(MB)";E={[math]::Round($_.FreeSpace / 1MB)}},
           @{N="Free Space %";E={[math]::Round(((100* ($_.FreeSpace))/ ($_.Capacity)),0)}} | Format-Table
  } # END foreach


  #
  # Disconnect from Virtualcenter
  Disconnect-VIServer -Confirm:$False

} # END if connect

Write-Host "`nEnd of script ...."
# END OF SCRIPT
