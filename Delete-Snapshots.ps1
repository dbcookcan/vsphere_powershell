#!/bin/pwsh
@"
===============================================================================
Title       : Delete-Snapshots.ps1
Description : Consolidate all snapshots on the VMware platform.

Usage       : .\Delete-Snapshots.ps1 or Powershell IDE
Date        : 01/12/2020
AUTHOR      : David Cook
REQUIRES    : VMware PowerCLI
===============================================================================
"@

#
# Set local vars
$VER=1.01
$ReportName = "Delete-Snapshots"
$ScriptName = $MyInvocation.MyCommand.Definition


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
  Write-Host "ERROR: Failed to connect to Virtual Center: $VIServer"

} Else {


  #
  # Successful login to Virtualcenter .. yay!


  #
  # Retrieve sorted list of all VMs on the platform
  $VMLIST=get-vm | Sort-Object
  #| where-object { $_.GuestId -like "centos*" }

  #
  # Loop through list
  ForEach( $VM in $VMLIST ){
    Write-Output $VM.Name
    $snaps=Get-Snapshot -vm $VM.Name

    # If snapshots exist, consolidate them including children.
    If ($snaps){
        Write-Host "Consolidating snapshots for "$VM.Name
        $snaps | Remove-Snapshot -RemoveChildren -RunAsync -confirm:$false
    } # end if snaps
  } # end foreach vm

  #
  # Disconnect from Virtualcenter
  Disconnect-Viserver -Confirm:$false

} # end if connect

# END OF SCRIPT
