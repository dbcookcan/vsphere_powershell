#!/bin/pwsh
param([string]$VIServer="",[string]$VIUsername="",[int]$DEBUG,[int]$EMAIL)
@"
===============================================================================
Title       : Delete-Snapshots.ps1
Description : Consolidate all snapshots on the VMware platform.
            : This script unilaterally cleans up ALL snapshots on the
            : esxi platform.
            : It will enumerate all virtual machines, loop through them
            : checking for existence of snapshot and consolidating (deleteing)
            : all including child snapshots.
            
            :  NOTE: This script submits the jobs ASYNCHRONOUSLY to the queue.
            :  NOTE: Uses the common include file construct.

Usage       : .\Delete-Snapshots.ps1 or Powershell IDE
Date        : 01/12/2020
AUTHOR      : David Cook
REQUIRES    : VMware PowerCLI
===============================================================================
History
Ver     Date            Who     Details
v1.00   01/12/2020      dbc     Initial delivery
===============================================================================
"@

#
# Set local vars
$VER=1.01
$ReportName = "Delete-Snapshots"
$ScriptName = $MyInvocation.MyCommand.Definition


#
# Include Advantech common header
. "/usr/.CredStore/Advan_Include.ps1"


#
# Connect to Virtual Center
$VC = Connect-VIServer -Server $VIServer -Port $port -user $VIUsername `
      -password $VIPassword -ErrorAction SilentlyContinue

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

  #
  # Loop through list
  ForEach( $VM in $VMLIST ){
    Write-Output $VM.Name
    $snaps=Get-Snapshot -vm $VM.Name

    # If snapshots exist, consolidate them including children.
    If ($snaps){
        Write-Host "Consolidating snapshots for "$VM.Name
        $snaps | Remove-Snapshot -RemoveChildren -confirm:$false
    } # end if snaps
  } # end foreach vm

  #
  # Disconnect from Virtualcenter
  Disconnect-Viserver -Confirm:$false

} # end if connect

# END OF SCRIPT
