function Get-VCDSInstances(){
    <#
    .SYNOPSIS
    Returns the Cloud Director Service instances currently running under the currently connected VMware Console Services Portal account.

    .DESCRIPTION
    Returns the Cloud Director Service instances currently running under the currently connected VMware Console Services Portal account.

    .PARAMETER EnvironmentId
    Optionally the Cloud Director Service Environment Id (the default is used if none is provided)

    .PARAMETER Name
    Optionally the Name of the Cloud Director Instance.

    .PARAMETER Id
    Optionally the Id of the Cloud Director Instance.

    .EXAMPLE
    Get-VCDSInstances
    Returns a collection of VCDS Instances in the default environment.

    .EXAMPLE
    Get-VCDSInstances -EnvironmentId "urn:vcdc:environment:3fccbd2a-003c-4303-8f1a-8569853236ac"
    Returns a collection of VCDS Instances in the environment with the Environment with the Id urn:vcdc:environment:3fccbd2a-003c-4303-8f1a-8569853236ac

    .EXAMPLE
    Get-VCDSInstances -Name "CloudDirector-TestInstance-01"
    Returns the Cloud Director instance with the name "CloudDirector-TestInstance-01" in the default environment if it exists.

    .EXAMPLE
    Get-VCDSInstances -Id urn:vcdc:vcdInstance:182297f8-36d0-4901-9f1d-42a2524fa091
    Returns the Cloud Director instance with the Id "urn:vcdc:vcdInstance:182297f8-36d0-4901-9f1d-42a2524fa091" in the default environment if it exists.

	.NOTES
    AUTHOR: Adrian Begg
    LASTEDIT: 2020-02-14
	VERSION: 1.0
    #>
    [CmdletBinding(DefaultParameterSetName="Default")]
    Param(
        [Parameter(Mandatory=$True, ParameterSetName="ById")]
            [ValidateNotNullorEmpty()]  [string] $Id,
        [Parameter(Mandatory=$True, ParameterSetName="ByName")]
            [ValidateNotNullorEmpty()]  [string] $Name,
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()]  [string] $EnvironmentId
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
    $ServiceURI = $Environment.ServiceURI

    # Setup a HashTable for the API call to the Cloud Gateway
    $InstancesAPIEndpoint = "$ServiceURI/environment/$($Environment.id)/organization/$($VCDService.OrganizationId)/instances"
    # A Hashtable of Request Parameters
    [Hashtable] $RequestParameters = @{
        URI = $InstancesAPIEndpoint
        Method = "Get"
        ContentType = "application/json"
        Headers = @{
            "Authorization" = "Bearer $($global:VCDService.AccessToken)"
            "Accept" = "application/json"
        }
        UseBasicParsing = $true
    }
    try{
        # First return the environments collection from CSP
        $Instances = ((Invoke-WebRequest @RequestParameters).Content | ConvertFrom-Json)
        # Check if any filters have been provided
        $Results = $Instances.values
        if($PSBoundParameters.ContainsKey("Name")){
            $Results = $Results | Where-Object {$_.name -eq $Name}
        }
        if($PSBoundParameters.ContainsKey("Id")){
            $Results = $Results | Where-Object {$_.id -eq $Id}
        }
        return $Results
    } catch {
        throw "An exception has occurred attempting to make the API call. $_"
    }
}