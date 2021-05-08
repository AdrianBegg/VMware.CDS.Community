function Get-VCDSInstanceMaintenance(){
    <#
    .SYNOPSIS
    Returns the Maintenance window for the provided Cloud Director Service instance.

    .DESCRIPTION
    Returns the weekly 2-hour maintenance window configured during which VMware checks if the VMware Cloud Director instance is eligible for upgrade and upgrade it if it is the case.
    
    The maintenance window Start Time/Day is set in UTC.

    .PARAMETER InstanceId
    The Cloud Director Instance Id

    .PARAMETER InstanceName
    The Cloud Director Instance Name

    .PARAMETER EnvironmentId
    Optionally The Cloud Director Service Environment Id (Default is used if none is provided)

    .EXAMPLE
    Get-VCDSInstanceMaintenance -InstanceName "CloudDirector-TestInstance-01"
    Returns the currently configured Maintenance Window for the instance named "CloudDirector-TestInstance-01"

    .NOTES
    AUTHOR: Adrian Begg
    LASTEDIT: 2021-05-08
	VERSION: 1.0
    #>
    [CmdletBinding(DefaultParameterSetName="ByInstanceId")]
    Param(
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceId")]
            [ValidateNotNullorEmpty()]  [string] $InstanceId,
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceName")]
            [ValidateNotNullorEmpty()]  [string] $InstanceName,
        [Parameter(Mandatory=$False, ParameterSetName="ByInstanceId")]
        [Parameter(Mandatory=$False, ParameterSetName="ByInstanceName")]
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

    if($PSCmdlet.ParameterSetName -eq "ByInstanceName") {
        # Check if an instance already exists with the provided Name
        $Instance = Get-VCDSInstances -EnvironmentId $Environment.id -Name $InstanceName
        if($Instance.count -eq 0){
            throw "An instance with the Name $InstanceName can not be found in the environment with the Id $($Environment.id) please check the Name and try again."
        }
    }
    if($PSCmdlet.ParameterSetName -eq "ByInstanceId") {
        # Check if an instance already exists with the provided Id
        $Instance = Get-VCDSInstances -EnvironmentId $Environment.id -Id $InstanceId
        if($Instance.count -eq 0){
            throw "An instance with the Id $InstanceId can not be found in the environment with the Id $($Environment.id) please check the Name and try again."
        }
    }

    # Setup a HashTable for the API call to the Cloud Gateway
    $InstanceOperationAPIEndpoint = "$ServiceURI/environment/$($Environment.id)/instances/$($Instance.id)/operations/CONFIGURE_MAINTENANCE"

    # A Hashtable of Request Parameters to the API
    [Hashtable] $RequestParameters = @{
        URI = $InstanceOperationAPIEndpoint
        Method = "Get"
        ContentType = "application/json"
        Headers = @{
            "Authorization" = "Bearer $($global:VCDService.AccessToken)"
            "Accept" = "application/json"
        }
        UseBasicParsing = $true
    }
    try{
        $MaintenanceResult = ((Invoke-WebRequest @RequestParameters).Content | ConvertFrom-Json)
    } catch {
        throw "An exception has occurred attempting to make the API call. $_"
    }
    # Parse the result and create an object with the current maintenance schedule
    $MaintenanceDay = ($MaintenanceResult.arguments | Where-Object {$_.id -eq "maintenanceDay"}).defaultValue
    $MaintenanceHour = ($MaintenanceResult.arguments | Where-Object {$_.id -eq "maintenanceHour"}).defaultValue
    
    # Define the Object to Post as Data to the API
    [PSObject] $MaintenanceWindow = New-Object -TypeName PSObject -Property @{
        MaintenanceDay = (($MaintenanceResult.arguments | Where-Object {$_.id -eq "maintenanceDay"}).options).$MaintenanceDay
        MaintenanceHoursUTC = (($MaintenanceResult.arguments | Where-Object {$_.id -eq "maintenanceHour"}).options).$MaintenanceHour
        MaintenanceHourStartUTC = $MaintenanceHour
    }
    return $MaintenanceWindow
}