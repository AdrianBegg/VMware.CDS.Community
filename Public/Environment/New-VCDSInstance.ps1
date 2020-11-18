function New-VCDSInstance(){
    <#
    .SYNOPSIS
    Creates a new instance of Cloud Director Service under the currently connected VMware Console Services Portal account.

    .DESCRIPTION
    Creates a new instance of Cloud Director Service under the currently connected VMware Console Services Portal account.

    If successfully invoked returns the Task Id of the job to create the instance

    .PARAMETER Name
    The Name of the CDS Instance for you to identify your instance

    .PARAMETER EnvironmentId
    Optionally The Cloud Director Service Environment Id (Default is used if none is provided)

    .PARAMETER UpgradeCategory
    The Cloud Director Upgrade "Station" for the deployed instance. Use the Get-VCDSUpgradeTracks cmdlet to view valid Stations.
    If none is provided the default will be used for the environment.

    .PARAMETER AdministratorPassword
    The password for the administrator user in the System Org

    .EXAMPLE
    New-VCDSInstance -Name "CDS-Instanace-01" -AdministratorPassword "Welcome@123"
    Creates a new VCDS Instance named "CDS-Instance-01" in the default environment with the default upgrade catagory.

    .EXAMPLE
    New-VCDSInstance -Name "CDS-Instanace-01" -UpgradeCategory "sp-main:alpha" -AdministratorPassword "Welcome@123"
    Creates a new VCDS Instance in the default environment using Upgrade Catagory "sp-main:alpha"

    .EXAMPLE
    New-VCDSInstance -Name "CDS-Instanace-01" -EnvironmentId "urn:vcdc:environment:3fccbd2a-003c-4303-8f1a-8569853236ac" -UpgradeCategory "sp-release:production" -AdministratorPassword "Welcome@123"
    Creates a new VCDS Instance in the environment with the Id "urn:vcdc:environment:3fccbd2a-003c-4303-8f1a-8569853236ac" using UpgradeCatagory "sp-release:production"

	.NOTES
    AUTHOR: Adrian Begg
    LASTEDIT: 2020-11-17
	VERSION: 1.1
    #>
    Param(
        [Parameter(Mandatory=$True)]
            [ValidateNotNullorEmpty()] [String] $Name,
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()] [String] $UpgradeCategory,
        [Parameter(Mandatory=$True)]
            [ValidateNotNullorEmpty()] [String] $AdministratorPassword,
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()] [String] $EnvironmentId
    )
    if(!$global:VCDService.IsConnected){
        throw "You are not currently connected to the VMware Console Services Portal (CSP) for VMware Cloud Director Service. Please use Connect-VCDService cmdlet to connect to the service and try again."
    }

    # Next check if the EnvironmentId has been provided and is valid
    if($PSBoundParameters.ContainsKey("EnvironmentId")){
        $Environment = $global:VCDService.VCDSEnvironments | Where-Object {$_.id -eq $EnvironmentId}
        if($Environment.count -eq 0){
            throw "An VCDS Environment with the Id $EnvironmentId can not be found. Please check the Id and try again."
        }
    } else {
        $Environment = $global:VCDService.DefaultEnvironment
    }
    # Setup a Service URI for the environment
    $ServiceURI = $Environment.url

    # Check if the UpgradeCategory was provided, if yes check if its valid, if no then retireve the default for the environment
    if($PSBoundParameters.ContainsKey("UpgradeCategory")){
        # Check if the provided Station is valid for the provided environment
        $UpgradeCategory = Get-VCDSUpgradeTracks -EnvironmentId $Environment.id -StationName $UpgradeCategory
        if($UpgradeCategory.Count -eq 0){
            throw "The provided Station Name $UpgradeCategory is not compatible with the provided environment VCDS Environment with the Id $EnvironmentId. Please check the Station Name is correct and try again."
        }
    } else {
        $UpgradeCategory = Get-VCDSUpgradeTracks -EnvironmentId $Environment.id -DefaultStation
    }

    # Check if an instance already exists with the provided Name
    $NamedInstance = Get-VCDSInstances -EnvironmentId $Environment.id -Name $Name
    if($NamedInstance.count -ne 0){
        throw "An instance with the Name $Name already exists in the environment, please check the Name and try again."
    }

    # Setup a HashTable for the API call to the Cloud Gateway
    $InstancesAPIEndpoint = "$ServiceURI/environment/$($Environment.id)/instances"
    [Hashtable] $htPayload = @{
        name = $Name
        domain = $null
        environmentId = $($Environment.id)
        upgradeCategory = $UpgradeCategory
        instanceParams = @{}
        password = $AdministratorPassword
    }

    # A Hashtable of Request Parameters
    [Hashtable] $RequestParameters = @{
        URI = $InstancesAPIEndpoint
        Method = "Post"
        ContentType = "application/json"
        Headers = @{
            "Authorization" = "Bearer $($global:VCDService.AccessToken)"
            "Accept" = "application/json"
        }
        Body = (ConvertTo-Json $htPayload)
        UseBasicParsing = $true
    }

    try{
        $CreateInstanceResult = ((Invoke-WebRequest @RequestParameters).Content | ConvertFrom-Json)
        return $CreateInstanceResult
    } catch {
        throw "An exception has occurred attempting to make the API call. $_"
    }
}
