#!/bin/pwsh
param([string]$VIServer="",[string]$VIUsername="",[string]$FindMAC="",[int]$DEBUG,[int]$EMAIL)
@"
===============================================================================
Title       : Find_MAC.ps1
Description : Find the virtual machine with the provided MAC address

Usage       : .\Find_MAC or Powershell IDE
Date        : 28/05/2021
AUTHOR      : David Cook
REQUIRES    : VMware PowerCLI
===============================================================================
History
Ver     Date            Who     Details
v1.00   28/05/2021      dbc     Initial delivery
===============================================================================
"@

#
# Set local vars
$VER=1.00
$ReportName = "Find-MAC"
$ScriptName = $MyInvocation.MyCommand.Definition


#
# Include Advantch common header
. "/usr/.CredStore/Advan_Include.ps1"


#$VIServer="vcenter.advan.ca"
#$VIusername="administrator@vsphere.local"
#$VIpassword="Ae2rpw4u!"
#$port=443

if ( $FindMAC -eq "" ){
   write-host "Must provide a MAC address to search for..."
   exit
}

#
# Connect to Virtual Center
$VC = Connect-VIServer -Server $VIServer -Port $port -user $VIusername -password $VIpassword -ErrorAction SilentlyContinue

If (!$?) {

  #
  # Error - failed to connect to the virtual center server
  Write-Host "ERROR: Failed to connect to Virtual Center: $VCHostName"

} Else {

  #
  # Successful login to Virtualcenter

  # Search ESXi for the host which has that IP address
  $myvm=(Get-VM | Get-NetworkAdapter | Select Parent, @{N="MAC";E={@($_.macaddress)}} | `
         Where { $_.MAC -like "*$FindMAC*" } | Select Parent)

  Write-Host "MAC "$FindMAC" is owned by "$myvm

  Disconnect-VIServer -Confirm:$False

}

Write-Host "`nEnd of script ...."
# END OF SCRIPT


