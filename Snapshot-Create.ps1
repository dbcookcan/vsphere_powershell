#!/bin/pwsh
param([string]$VIServer="",[string]$VIUsername="",[string]$myhost,[string]$mess,[int]$DEBUG)
@"
===============================================================================
Title       : Snapshot-Create.ps1
Description : Creates a snapshot of a virtual machine provided on the
            : command line.

            : Creates a VM snapshot of a virtual machine whose IP address
            : matches the DNS ip provided by [hostname]. Note the difference
            : here between resolvable DNS hostname and the name given a VM
            : within the ESXi environment.

            : Use this prior to performaing yum updates etc. in order to
            : have a rollback option.

            : Assumptions:
            : Will scan all available VM interfaces to find a match.
            : Assumes a unique resolvable IP address per DNS entry. 

            : Exit Codes
            : 0 - normal completion
            : 1 - no hostname provided
            : 2 - failed DNS result
            : 3 - host is not in the vmware cluster
            : 9 - failed vm snapshot completion

Usage       : .\Snapshot-Create.ps1 [vcenter] [VC Acct] [hostname] [DEBUG]
Date        : 08/12/2020
AUTHOR      : David Cook
REQUIRES    : VMware PowerCLI
===============================================================================
History
Ver     Date            Who     Details
v1.00   08/12/2020      dbc     Initial delivery
===============================================================================
"@


#
# Set local vars
$VER=1.00
$ReportName = "Create-Snapshot"
$ScriptName = $MyInvocation.MyCommand.Definition


#
# Include Kira common header
. "/opt/automate/powershell/Prod/Kira_Include.ps1"



# Check that we received a hostname
if ( $myhost -eq "" ){
   Write-Host "No hostname provided."
   exit 1
}


# Retreive DNS entry to get IP address
$hostip=getent hosts $myhost | awk '{print $1}'
if ( $hostip -eq $NULL ){
   Write-Host "Failed to get a DNS result for host $myhost."
   exit 2
}


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

  # Check if we recevied a message on the command line.
  # If so, create the snapshot name based on the command line plus date. If
  # not, use a generic name.
  # The date format will be YYYY-MM-DD HH:MM:SSZ
  if ( $mess -eq "" ){
     $snapname="api-created snapshot - "+(Get-Date -format u)
  } else {
     $snapname="$mess - "+(Get-Date -format u)
  }


  # Search ESXi for the host which has that IP address
  $myvm=(Get-VM | Select Name, @{N="Address";E={@($_.guest.IPAddress)}} | `
         Where { $_.Address -like "*$hostip*" } | Select Name) 

  # Check if we found the VM
  if ( $myvm -eq $NULL ){
     # If null, we failed to find the VM in this cluster.
     # Either this machine exists in a different EXi cluster or the machine
     # in question is not a VM.
     Write-Host "Host $myhost is not a VM in this cluster."
     exit 3
  }

  if( $DEBUG -gt 0 ){ 
      Write-Host "Creating snapshot for host $myhost ( VM:"$myvm.Name")."
  }

  # Create a new snapshot before we do our yum updates
  $newsnap = New-Snapshot -vm $myvm.Name -name $snapname -confirm:$false `
             -runasync:$false
 
  if ( $newsnap -eq $NULL ){
     # we failed to create snapshot
     exit 9
  }

}

#
# EOF
# 
