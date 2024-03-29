#!/bin/env pwsh
param([string]$VIServer="",[string]$VIUsername="",[int]$DEBUG)
@"
===============================================================================
Title       : vSPhere-Licenses.ps1
Description : Create CSV inventory of VMware licenses

Usage       : .\vSPhere-Licenses.ps1 or Powershell IDE
Date        : 24/09/2014
AUTHOR      : David Cook
REQUIRES    : VMware PowerCLI
===============================================================================
History
Ver     Date            Who     Details
v1.00   24/09/2014      dbc     Initial delivery
===============================================================================
"@

#
# Set vars
$ReportName = "vSphere License Inventory"
$ScriptName = $MyInvocation.MyCommand.Definition

#
# Include Advantech common header
. "/usr/.CredStore/Advan_Include.ps1"

# Define Report (Output) file
$Filespec = $OutputBaseDir + "/" + $ReportName.Replace(" ","_") +"-"+ `
                        $VIServer +"-"+ $filedate+".csv"


#
#
# Connect to Virtual Center
$VC = Connect-VIServer -Server $VIServer -Port $port -user $VIUsername `
          -password $VIPassword -ErrorAction SilentlyContinue

#
# If Connection error, fail
If (!$?) {

  #
  # Error - failed to connect to the virtual center server
  Write-Host "ERROR: Failed to connect to Virtual Center: $VCHostName"

} Else {
  #
  # Connection Successful - process the report

  # Define the Output Array
  $Output=@()

  #
  # Header data
  #
  # Header - First line (Script Name in VirtualCtr column)
  $Header = "" | Select VC, Name, Key, Total, Used, ExpirationData, Information
  $Header.VC = "Script: $ScriptName"
  $Output += $Header

  # Header - Second line (Output location in VirtualCtr column)
  $Header = "" | Select VC, Name, Key, Total, Used, ExpirationData, Information
  $Header.VC = "Saved As: $Filespec"
  $Output += $Header


  # Loop through the licenses
  $ServiceInstance = Get-View ServiceInstance
  Foreach ($LicenseMan in Get-View ($ServiceInstance | Select -First 1).Content.LicenseManager) {
     Foreach ($License in ($LicenseMan | Select -ExpandProperty Licenses)) {
        $LineData = "" |Select VC, Name, Key, Total, Used, ExpirationDate , Information
        $LineData.VC = ([Uri]$LicenseMan.Client.ServiceUrl).Host
        $LineData.Name= $License.Name
        $LineData.Key= $License.LicenseKey
        $LineData.Total= $License.Total
        $LineData.Used= $License.Used
        $LineData.Information= $License.Labels | Select -expand Value
        $LineData.ExpirationDate = $License.Properties | Where { $_.key -eq "expirationDate" } | Select -ExpandProperty Value

        # Now add the array to the output
        $Output += $LineData
     } # End Each license loop
  } # End Each VC instance loop

  #
  # Disconnect from Virtualcenter
  Do-Disconnect


  #
  # Output the report file
  $Output | Export-Csv $Filespec

  Write-Host "Report written as $Filespec"

}

Write-Host "End of Script"

# END OF SCRIPT
