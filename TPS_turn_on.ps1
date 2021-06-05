#!/bin/pwsh
param([string]$VIServer="",[string]$VIUsername="",[int]$DEBUG,[int]$EMAIL)
@"
===============================================================================
Title       : TPS_turn_on.ps1
Description : Turn on VMware Transparent Page Sharing

Usage       : .\TPS_on.ps1 or Powershell IDE
Date        : 30/04/2021
AUTHOR      : David Cook
REQUIRES    : VMware PowerCLI
HISTORY     : v1.0 30/04/2021 initial delivery
===============================================================================
History
Ver     Date            Who     Details
v1.00   30/04/2021      dbc     Initial delivery
v1.02   27/05/2021	dbc	Cleanup vm loop and console output.
===============================================================================
"@

#
# Set local vars
$VER=1.02
$ReportName = "Turn On Transparent Page Sharing"
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
  Write-Host "ERROR: Failed to connect to Virtual Center: $VCHostName"

} Else {

  #
  # Successful login to Virtualcenter

  $HostList = Get-VMHost | Sort-Object
  foreach( $myHost in $HostList ){
    write-host ""
    write-host "Host: $myHost"

    $HostTPS = $myHost | Get-AdvancedSetting -Name Mem.ShareForceSalting
    Switch ($HostTPS.Value)
    {
       0 { "TPS between VMs on same host"}
       1 { "TPS between VMs with same salt"}
       2 { "TPS is Off"}
    } # END SWITCH

    #
    # Set TPS host value
    if ($HostTPS.Value -ne 1 ){
       if ($myHost.Name -eq "192.168.10.29"){
          write-host "Matched Witness appliance - ignoring"
       }else{
          $myHost | Get-AdvancedSetting -Name Mem.ShareForceSalting ` 
                  | Set-AdvancedSetting -Value 1
          $myHost | Get-AdvancedSetting -Name Mem.AllocGuestLargePage `
                  | Set-AdvancedSetting -Value 0

          write-host "Updating host TPS value"
       } # END if host ".29"
    } # END IF TPS -ne 1

    #
    # Get full VM list
    $vms = Get-View -ViewType VirtualMachine | where {-not $_.config.template}  

  } # END HOST LIST


  # Get view list of all VMs on the platform
  $ViewList=Get-VM | Get-View | Select-Object Name, `
      @{Name="Salt"; `
      E={($_.Config.ExtraConfig | Where-Object {$_.Key -eq "sched.mem.pshare.salt"}).Value}} 


  # Loop through view checking for TPS config value
  foreach( $vm in $ViewList){
     if( $vm.Salt -eq 0){
       "{0,-15} -> {1,-5}" -f $vm.Name, "OK"

     }else{

       # Print the action
       "{0,-15} -> {1,-50}" -f $vm.Name, "Turning on TPS - cold start of VM required"

       # New view object to reconfigure machine
       $myview=Get-View -ViewType VirtualMachine | Where {$_.Name -eq $vm.Name}
       $vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec

       # Add extra value
       $extra = New-Object VMware.Vim.optionvalue
       $extra.Key="sched.mem.pshare.salt"
       $extra.Value=0
       $vmConfigSpec.extraconfig += $extra

       # Reconfigure machine
       $myview.ReconfigVM($vmConfigSpec)

     } # END IF SALT -ne 0

   } # END Loop through views

   Disconnect-VIServer -Confirm:$False

} # ENDIF else login

Write-Host "`nEnd of script ...."
# END OF SCRIPT


