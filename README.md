# VMware.CDS.Community
A PowerShell module to interact with the VMware Cloud Director service using the VMware Cloud Services Portal (CSP).

**Please Note**: This is a community supported module. It is not provided by, affiliated with or supported by VMware.

## Project Owner
Adrian Begg (@AdrianBegg)

## Tested Versions
* PowerShell Core: 7.1
* VMware Cloud Director service (17 November 2020 Release)

## Functional Coverage
The following cmdlets are available in the current release.
### Session:
* Connect-VCDService : Establishes a new connection to the VMware Cloud Director service using an API Token from the VMware Console Services Portal
* Disconnect-VCDService : This cmdlet removes the currently connected VMware Cloud Director service connection.

### Environment
* Get-VCDSEnvironments : Returns a collection of Cloud Director Service environments for the default CSP environment on the currently available under the currently connected VMware Console Services Portal account.
* Get-VCDSInstances : Returns the Cloud Director Service instances currently running under the currently connected VMware Console Services Portal account.
* Get-VCDSUpgradeTracks : Queries the configurable upgrade tracks and stations for the provided Cloud Director Service environment.
* New-VCDSInstance : Creates a new instance of Cloud Director Service under the currently connected VMware Console Services Portal account.
* Remove-VCDSInstance : Deletes an instance of Cloud Director Service under the currently connected VMware Console Services Portal account.

### Operations:
* New-VCDSSupportBundle : Generates a Cloud Director support bundle
* Register-VCDSSDDC : Associate an VMC SDDC with a VMware Cloud Director service instance.
* Set-VCDSDomain : Configures a Custom DNS name and X.509 SSL certificates for a Cloud Director service instance and Console Proxy endpoints.
* Set-VCDSProviderAdminPassword : Sets a new password for the administrator user of a Cloud Director service instance.
* Set-VCDSIdPSettings : Configure CSP (VMware Cloud Services) as Identity Provider for instance's System Org for Single Sign-On.

### Administration:
* Get-VCDSTasks : Returns a collection of Tasks from the connected Cloud Director Service environment.
* Watch-VCDSTaskCompleted : A helper function to monitor a running task and returns True when the task completes.

All of the cmdlets in the module should have well described PowerShell help available. For detailed help including examples please use `Get-help <cmdlet> -Detailed` (e.g. `Get-help New-VCDSInstance -Detailed`).

### Change Log
**v0.3 (18th November 2020)**
* Added cmdlet **Set-VCDSIdPSettings** to allow for System Org login using the VMware Cloud Services Identity Provider
* Removed **Get-VCDSTemplates** cmdlet due to deprecation of "Templates" in the service for GA
* Added **Get-VCDSUpgradeTracks** cmdlet to access Tracks & Stations information for Cloud Director service
* Adjusted Operations cmdlets to use the /environment/{env.id}/instances/{instance.id}/operations/invokeOperation API (/environment/{env.id}/instances/{instance.id}/operations/invoke deprecated)
* Adjusted Environment cmdlets to support Upgrade Stations/Tracks due to deprecation of "Templates" in the service for GA

**v0.2 - Initial release (31st August 2020)**
* Added cmdlet for resetting Provider Administrator password
* Added support for using cmdlets when VMware Cloud Organization has access to multiple CDS environments (e.g. Initial Availability us-west, Initial Availability eu-central-1)

**v0.1 - Initial release (7th July 2020)**
* Initial public release