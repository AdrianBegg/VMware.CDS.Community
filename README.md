# VMware.CDS.Community
A PowerShell module to interact with the VMware Cloud Director service using the VMware Cloud Services Portal (CSP).

**Please Note**: This is a community supported module. It is not provided by, affiliated with or supported by VMware or AWS. 

## Project Owner
Adrian Begg (@AdrianBegg)

## Tested Versions
* PowerShell Core: 7.1
* VMware Cloud Director service ([13 April 2021 Release](https://docs.vmware.com/en/VMware-Cloud-Director-service/services/rn/VMware-Cloud-Director-Service-Release-Notes.html))

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
* Get-VCDSInstanceMaintenance : Returns the currently configured Maintenance window for the provided Cloud Director Service instance.
* Set-VCDSInstanceMaintenance : Configures the Maintenance window for the provided Cloud Director Service instance.

### Administration:
* Get-VCDSTasks : Returns a collection of Tasks from the connected Cloud Director Service environment.
* Watch-VCDSTaskCompleted : A helper function to monitor a running task and returns True when the task completes.

All of the cmdlets in the module should have well described PowerShell help available. For detailed help including examples please use `Get-help <cmdlet> -Detailed` (e.g. `Get-help New-VCDSInstance -Detailed`).

### Change Log
**0.5 (13th July 2021)**
* Adjusted **Register-VCDSSDDC** cmdlet added support for -ProxyVMNetwork switch to control SDDC Proxy network placement

**v0.4 (7th July 2021)**
* Adjusted **Get-VCDSUpgradeTracks** cmdlet -StationName parameter handling to support changes in the upgrade-tracks-and-stations API operation
* Adjusted **New-VCDSInstance** cmdlet to support changes in the Get-VCDSUpgradeTracks -StationName parameter
* Adjusted **New-VCDSSupportBundle** cmdlet to support changes in the invokeOperation API operation
* Adjusted **Set-VCDSIdPSettings** cmdlet to support changes in the invokeOperation API operation
* Adjusted **Set-VCDSProviderAdminPassword** cmdlet to support changes in the invokeOperation API operation
* Adjusted **Set-VCDSDomain** cmdlet to support changes in the invokeOperation API operation
* Added **Set-VCDSInstanceMaintenance** cmdlet to support adjusting the Cloud Director service maintenance window
* Added **Get-VCDSInstanceMaintenance** cmdlet to query the Maintenance window for the provided Cloud Director Service instance.
* Fixed a number of typos in comments and documentation

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