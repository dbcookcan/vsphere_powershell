#!/bin/pwsh
param([string]$VIServer="",[string]$VIUsername="",[int]$Debug)
@"
===============================================================================
Title       : Manage_PG.ps1
Description : Manage Port Group configurations across all blades within the
	    : standard vSwitch "VM Network" present in all vSphere configs.
	    : NOTE: We are NOT using dvSwitches as our license does not
	    :       include this feature.
	    : Standard vSwitches are per-host and care must be taken
	    : to keep them in-sync across all hosts.
	    : Create unique port groups for each lab environment. This will =
	    : allow us to sequester traffic if req'd between environments.
	    : NOTE: Initial deploy these are still on SINGLE vlan, but we
	    :       can change this later and script will support.
	    : Define the Portgroup names & Vlan to be assigned in array.
	    : Will create/modify port groups as needed (eg vlan changes) so
	    : it is safe to re-run or cron from job server.
Usage	    :	. "./Manage_PG.ps1"
Date        : 31/05/2021
AUTHOR      : David Cook
REQUIRES    : VMware PowerCLI
===============================================================================
History
Ver		Date		Who	Details
v1.00	31/05/2021	dbc	Initial delivery
===============================================================================
"@

#
# Include Advantech common header
. "/usr/.CredStore/Advan_Include.ps1"


#
# Declare Defaults/Constants
$VER=1.01
$Datacenter="Datacenter-01"
$Cluster="Cluster-EVC-01"
$vSwitch="vSwitch0"
$DefaultPG="VM Network"

#
# Function for loading PG variables into multi-dimensional array
Function New-UserObject ($PortGroup, $PGVlan) {
         New-Object PSObject -Property @{
   	     PortGroup = $PortGroup
             PGVlan = $PGVlan }
} # END: New-UserObject function


#
# Define required port groups and the vlan they belong to in this array.
$myPGGroups = @()
$myPGGroups += New-UserObject "All_Trunks" "4095"
$myPGGroups += New-UserObject "Storage" "3"
$myPGGroups += New-UserObject "VSAN" "3"
$myPGGroups += New-UserObject "Guest_Secure_Side" "4"
$myPGGroups += New-UserObject "Guest_Client_Side" "5"
$myPGGroups += New-UserObject "IOT_Untrusted" "6"
$myPGGroups += New-UserObject "Management Network" "10"
$myPGGroups += New-UserObject "Mgnt_Net_VMs" "10"
$myPGGroups += New-UserObject "Internet" "500"
$myPGGroups += New-UserObject "Test Vlan 17" "17"


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
  # Congrats - we connected to vCenter!

  # Retrieve the primary vSwitch from each of the hosts in the
  # Datacenter/Cluster which we need.
  $vmhosts=Get-Datacenter $Datacenter -EA SilentlyContinue | `
           Get-Cluster $Cluster -EA SilentlyContinue | `
           Get-VMHost -EA SilentlyContinue

  If (!$?) {

     # Error finding hosts within datacenter/cluster scope
     Write-Host "Error finding hosts within scope."
     $ERRTOT++

  } else {

     #
     # Loop through the hosts to check the network switches and port groups
     ForEach ($vmhost in $vmhosts){

        # Check Default PG
        $IsDefPG=Get-VirtualSwitch -VMhost $vmhost -Name $vSwitch `
            -EA SilentlyContinue | `
            Get-VirtualPortGroup -Name $DefaultPG -EA SilentlyContinue

        If (!$?) {
           $ERRTOT++
           Write-Host "Failed to find default PG on $vmhost!"
        } else {
           If ($DEBUG -ne 0 ) { Write-Host "Default PG ok on $vmhost" }

        } # END: Check Default PG


        #
        # Loop through the array applying all PGs to each blade in turn
        foreach($myPG in $myPGGroups){

           if( $DEBUG -gt 0 ) { write-host "Working with PG "$myPG.PortGroup }

           if( $myPG -eq "Management Network" ) {
              write-host "MGNT Network identified"
              exit
           }

           #
           # Check if PortGroup already exits, add/modify if neccessary
           $PGexist=Get-VirtualSwitch -VMhost $vmhost -Name $vSwitch `
             -EA SilentlyContinue | `
             Get-VirtualPortGroup -Name $myPG.PortGroup -EA SilentlyContinue

           If (!$?) {
              # Add new VirtualPortgroup
              " - Adding PG {0,-10} on {1,10}" -f $myPG.PortGroup, $vmhost
              If ($DEBUG -ne 0 ) { Write-Host "Adding PG on $vmhost" }

              Get-VirtualSwitch -VMhost $vmhost -Name $vSwitch `
	          -EA SilentlyContinue | `
                  New-VirtualPortGroup -Name $myPG.PortGroup `
	          -VLanID $myPG.PGVlan -EA SilentlyContinue


              # Check return code, cumulate error counter
              If (!$?) {  $ERRTOT++ }

           } else {
              If ($DEBUG -ne 0 ) {
		   " - PG {0,-10} already exists on {1,10}" -f $myPG.PortGroup, $vmhost
              } # END: Debug statement



              # Do not process Management Network on Witness appliance
              if ( ($myPG.PortGroup -eq "Management Network"  ) `
                   -and ( "$vmhost" -eq "192.168.10.29" )) {

                   if($DEBUG -ne 0) {
                       Write-host "Not Processing this PG on Witness"
                   }
              } else {

                # Check if Vlan is the same, if not modify
                if ( $PGexist.Vlanid -ne $myPG.PGVlan ){
                   If ($DEBUG -ne 0) {
		      Write-Host "Trying to change the PG VlanID"
	           } # END Debug

	           # Modify is 2-step process. Retrieve, then set.
                   $updpg=Get-VirtualSwitch -VMhost $vmhost -Name $vSwitch `
                       -EA SilentlyContinue | `
                       Get-VirtualPortGroup -Name $myPG.PortGroup `
	               -EA SilentlyContinue

                   # Do the update here
                   Set-VirtualPortGroup -VirtualPortGroup $updpg `
		       -VlanId $myPG.PGVlan -EA SilentlyContinue

                } # END: Check if vlan is the same
              } # END: Not on Witness

           } # END: Check if portgroup already exists

        } # END: Find valid portgroups on each blade

    } # END: Loop through hosts

  } # END: Retrieve valid list of hosts


  # Check if we had any errors
  If ($ERRTOT -gt 0 ) {
     Write-Host "We have encountered errors"
  } else {
     Write-Host "No errors"
  } # END: Check if errors


  #
  # Disconnect from Virtualcenter
  Disconnect-VIServer -Confirm:$False

} # END: Connect vCenter

#
# EOF
#

