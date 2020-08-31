function Remove-VCDSInstance(){
    <#
    .SYNOPSIS
    Deletes an instance of Cloud Director Service under the currently connected VMware Console Services Portal account.

    .DESCRIPTION
    Deletes an instance of Cloud Director Service under the currently connected VMware Console Services Portal account.

    This cmdlet removes an instance PERMANENTLY. All tasks in this instance will be terminated.

    All data and configuration settings in this instance will be lost.

    All UI and API access to this instance will be lost.

    This action cannot be undone.

    .PARAMETER EnvironmentId
    Optionally The Cloud Director Service Environment Id (Default is used if none is provided)

    .PARAMETER Name
    The Name of the CDS Instance to remove

    .PARAMETER Id
    The Id of the CDS Instance to remove

    .PARAMETER Force
    If $true the instance will be removed without prompting.

    .EXAMPLE
    Remove-VCDSInstance -EnvironmentId "urn:vcdc:environment:3fccbd2a-003c-4303-8f1a-8569853236ac" -Name "CDS-Example-01"
    Removes the CDS instance with the Name "CDS-Example-01" from the CDS Environment with the Id urn:vcdc:environment:3fccbd2a-003c-4303-8f1a-8569853236ac

	.NOTES
    AUTHOR: Adrian Begg
    LASTEDIT: 2020-02-14
	VERSION: 1.0
    #>
    [CmdletBinding(DefaultParameterSetName="ById")]
    Param(
        [Parameter(Mandatory=$True, ParameterSetName="ByName")]
            [ValidateNotNullorEmpty()] [String] $Name,
        [Parameter(Mandatory=$True, ParameterSetName="ById")]
            [ValidateNotNullorEmpty()] [String] $Id,
        [Parameter(Mandatory=$False, ParameterSetName="ByName")]
        [Parameter(Mandatory=$False, ParameterSetName="ById")]
            [bool]$Force = $false,
        [Parameter(Mandatory=$False, ParameterSetName="ByName")]
        [Parameter(Mandatory=$False, ParameterSetName="ById")]
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

    if($PSCmdlet.ParameterSetName -eq "ByName") {
        # Check if an instance already exists with the provided Name
        $Instance = Get-VCDSInstances -EnvironmentId $Environment.Id -Name $Name
        if($Instance.count -eq 0){
            throw "An instance with the Name $Name can not be found in the environment with the Id $($Environment.Id) please check the Name and try again."
        }
    }
    if($PSCmdlet.ParameterSetName -eq "ById") {
        # Check if an instance already exists with the provided Id
        $Instance = Get-VCDSInstances -EnvironmentId $Environment.Id -Id $Id
        if($Instance.count -eq 0){
            throw "An instance with the Id $Id can not be found in the environment with the Id $($Environment.Id) please check the Name and try again."
        }
    }
    # Warn the users that this is dangerous
    if(!$Force){
        Write-Warning "This cmdlet will delete the Cloud Director Instance with the Id $($Instance.id). All tasks in this instance will be terminated. All data and configuration settings in this instance will be lost. This action cannot be undone. Are you sure you wish to proceed?" -WarningAction Inquire
    }

    # Setup a HashTable for the API call to the Cloud Gateway
    $InstanceAPIEndpoint = "$ServiceURI/environment/$($Environment.Id)/instances/$($Instance.id)"

    # A Hashtable of Request Parameters
    [Hashtable] $RequestParameters = @{
        URI = $InstanceAPIEndpoint
        Method = "Delete"
        ContentType = "application/json"
        Headers = @{
            "Authorization" = "Bearer $($global:VCDService.AccessToken)"
            "Accept" = "application/json"
        }
        UseBasicParsing = $true
    }
    try{
        # First return the environments collection from CSP
        $TaskId = ((Invoke-WebRequest @RequestParameters).Content | ConvertFrom-Json)
        return $TaskId
    } catch {
        throw "An exception has occurred attempting to make the API call. $_"
    }
}