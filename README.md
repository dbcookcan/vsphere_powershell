# vsphere_powershell
Library of PowerShell programs for managing VMware ESXi platforms. This will work with PowerShell on Windows and PowerShell Core on linux.

# Shared Resources and Credential Management
XXX_Include.ps1 - Library of common functions to be .source included in standard programs. It includes functionality for retrieving security credentials from a standardized set of files akin to ssh keys.

Gen-Masterfile.ps1 - Generate a master key which is a 24-byte salt value for the credential store.
Gen-Passwordfile.ps1 - Generates a user's credential store salted by the MasterFile key.

# Scripts
Delete-Snapshots.ps1 - Unilaterly consolidates (deletes) all snapshots on a VMware esxi platform.
