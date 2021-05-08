function Set-VCDSInstanceMaintenance(){
    <#
    .SYNOPSIS
    Configures the Maintenance window for the provided Cloud Director Service instance.

    .DESCRIPTION
    Configures the weekly 2-hour maintenance window during which VMware checks if the VMware Cloud Director instance is eligible for upgrade and upgrade it if it is the case.
    
    The maintenance window Start Time/Day is set in UTC.

    .PARAMETER InstanceId
    The Cloud Director Instance Id

    .PARAMETER InstanceName
    The Cloud Director Instance Name

    .PARAMETER EnvironmentId
    Optionally The Cloud Director Service Environment Id (Default is used if none is provided)

    .PARAMETER MaintenanceDay
    The Maintenance Window Day (e.g. Sunday)
    Please Note: The maintenance window Start Time/Day is set in UTC.

    .PARAMETER MaintenanceStartTime
    The Maintenance Start Time Hour (UTC) as an Integer (e.g. 0 = 00:00, 13 = 13:00).
    Please Note: The maintenance window must start on the hour (e.g. 01:00 or 23:00) and duration will be 2 hours from the start time.

    .PARAMETER SkipNextWindow
    If this flag is set the VMware Cloud Director instance is excluded from the current week's scheduled maintenance window

    .EXAMPLE
    Set-VCDSInstanceMaintenance -InstanceName "CloudDirector-TestInstance-01" -MaintenanceDay "Friday" -MaintenanceStartTime 9
    Sets the maintenance window for the instance named "CloudDirector-TestInstance-01" to commence weekly on Friday at 9:00 - 11:00 UTC

    .EXAMPLE
    Set-VCDSInstanceMaintenance -InstanceName "CloudDirector-TestInstance-01" -SkipNextWindow
    Marks the the instance named "CloudDirector-TestInstance-01" to skip the next weekly maintenance window

    .NOTES
    AUTHOR: Adrian Begg
    LASTEDIT: 2021-05-07
	VERSION: 1.0
    #>
    [CmdletBinding(DefaultParameterSetName="ByInstanceId")]
    Param(
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceId")]
            [ValidateNotNullorEmpty()]  [string] $InstanceId,
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceName")]
        [Parameter(Mandatory=$True, ParameterSetName="SkipNextWindow")]
            [ValidateNotNullorEmpty()]  [string] $InstanceName,
        [Parameter(Mandatory=$False, ParameterSetName="ByInstanceId")]
        [Parameter(Mandatory=$False, ParameterSetName="ByInstanceName")]
        [Parameter(Mandatory=$False, ParameterSetName="SkipNextWindow")]
            [ValidateNotNullorEmpty()] [String] $EnvironmentId,
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceId")]
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceName")]
            [string]$MaintenanceDay,
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceId")]
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceName")]
            [int]$MaintenanceStartTime,
        [Parameter(Mandatory=$True, ParameterSetName="SkipNextWindow")]
            [switch]$SkipNextWindow
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

    if($PSCmdlet.ParameterSetName -in ("ByInstanceName","SkipNextWindow")) {
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

    # Declare a day mapping object
    [Hashtable] $DaysOfWeek = @{
        Sunday = 0
        Monday = 1
        Tuesday = 2
        Wednesday = 3
        Thursday = 4
        Friday = 5
        Saturday = 6
    }

    # Check if only the -SkipNextWindow switch was provided and get the current values
    if($PSCmdlet.ParameterSetName -eq "SkipNextWindow") {
        $CurrentConfig = Get-VCDSInstanceMaintenance -InstanceId $Instance.id
        $MaintenanceDay = $CurrentConfig.MaintenanceDay
        $MaintenanceStartTime = $CurrentConfig.MaintenanceHourStartUTC
    }

    # Setup a HashTable for the API call to the Cloud Gateway
    $InstanceOperationAPIEndpoint = "$ServiceURI/environment/$($Environment.id)/instances/$($Instance.id)/operations/invokeOperation"
    [Hashtable] $htPayload = @{
        operationType = "CONFIGURE_MAINTENANCE"
        arguments = @{
            maintenanceDay = ($DaysOfWeek.$MaintenanceDay).ToString()
            maintenanceHour = ($MaintenanceStartTime).ToString()
            upgradeAfter = ($SkipNextWindow).IsPresent
        }
    }

    # A Hashtable of Request Parameters
    [Hashtable] $RequestParameters = @{
        URI = $InstanceOperationAPIEndpoint
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
        $SetMaintenanceTask = ((Invoke-WebRequest @RequestParameters).Content | ConvertFrom-Json)
        return $SetMaintenanceTask
    } catch {
        throw "An exception has occurred attempting to make the API call. $_"
    }
}