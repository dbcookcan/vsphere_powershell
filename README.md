# vsphere_powershell
Library of PowerShell programs for managing VMware ESXi platforms. This will work with PowerShell on Windows and PowerShell Core on linux.

# Shared Resources and Credential Management
XXX_Include.ps1 - Library of common functions to be .source included in standard programs. It includes functionality for retrieving security credentials from a standardized set of files akin to ssh keys.

Gen-Masterfile.ps1 - Generate a master key which is a 24-byte salt value for the credential store.

Gen-Passwordfile.ps1 - Generates a user's credential store salted by the MasterFile key.

# Scripts
Backup-vSPhere-Config.ps1 - Backup ESXi config to local directory and push to AWS S3 bucket.

Delete-Snapshots.ps1 - Unilaterly consolidates (deletes) all snapshots on a VMware esxi platform.

vSphere-guest-disk-sizes.ps1 - Report VM disk partition sizes, free space and datastore fill percentage.

vSphere-Licenses.ps1 - Report detailing all vSphere licenses (vcenter, esxi, vSAN, etc) held within VMware installation.
