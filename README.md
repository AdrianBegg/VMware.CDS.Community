# VMware.CDS.Community
A PowerShell module to interact with the VMware Cloud Director service (Initial Access Release) using the VMware Cloud Services Portal (CSP).

**Please Note**: This is a community supported module. It is not provided by, affiliated with or supported by VMware.

## Project Owner
Adrian Begg (@AdrianBegg)

## Tested Versions
* PowerShell Core: 7.0.3
* VMware Cloud Director service (Initial Access Release 22 May 2020)

## Functional Coverage
The following cmdlets are available in the current release.
### Session:
* Connect-VCDService : Establishes a new connection to the VMware Cloud Director service using an API Token from the VMware Console Services Portal
* Disconnect-VCDService : This cmdlet removes the currently connected VMware Cloud Director service connection.

### Environment
* Get-VCDSEnvironments : Returns a collection of Cloud Director Service environments for the default CSP environment on the currently available under the currently connected VMware Console Services Portal account.
* Get-VCDSTemplates : Returns the available templates for the provided Cloud Director Service environment.
* Get-VCDSInstances : Returns the Cloud Director Service instances currently running under the currently connected VMware Console Services Portal account.
* New-VCDSInstance : Creates a new instance of Cloud Director Service under the currently connected VMware Console Services Portal account.
* Remove-VCDSInstance : Deletes an instance of Cloud Director Service under the currently connected VMware Console Services Portal account.

### Operations:
* New-VCDSSupportBundle : Generates a Cloud Director support bundle
* Register-VCDSSDDC : Associate an VMC SDDC with a VMware Cloud Director service instance.
* Set-VCDSDomain : Configures a Custom DNS name and X.509 SSL certificates for a Cloud Director service instance and Console Proxy endpoints.
* Set-VCDSProviderAdminPassword : Sets a new password for the administrator user of a Cloud Director service instance.

### Administration:
* Get-VCDSTasks : Returns a collection of Tasks from the connected Cloud Director Service environment.
* Watch-VCDSTaskCompleted : A helper function to monitor a running task and returns True when the task completes.

All of the cmdlets in the module should have well described PowerShell help available. For detailed help including examples please use `Get-help <cmdlet> -Detailed` (e.g. `Get-help New-VCDSInstance -Detailed`).

### Change Log
**v0.2 - Initial release (31st August 2020)**
* Added cmdlet for resetting Provider Administrator password
* Added support for using cmdlets when VMware Cloud Organization has access to multiple CDS environments (e.g. Initial Availability us-west, Initial Availability eu-central-1)

**v0.1 - Initial release (7th July 2020)**
* Initial public release