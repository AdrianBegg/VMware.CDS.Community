function Get-VCDSInstances(){
    <#
    .SYNOPSIS
    Returns the Cloud Director Service instances currently running under the currently connected VMware Console Services Portal account.

    .DESCRIPTION
    Returns the Cloud Director Service instances currently running under the currently connected VMware Console Services Portal account.

    .PARAMETER EnvironmentId
    The Cloud Director Service Environment Id
    
    .PARAMETER Name
    Optionally the Name of the Instance.
    
    .PARAMETER Id
    Optionally the Id to Instance.

    .EXAMPLE
    Get-VCDSInstances -EnvironmentId "urn:vcdc:environment:3fccbd2a-003c-4303-8f1a-8569853236ac"
    Returns a collection of VCDS Instances in the environment with the Environment with the Id urn:vcdc:environment:3fccbd2a-003c-4303-8f1a-8569853236ac

	.NOTES
    AUTHOR: Adrian Begg
    LASTEDIT: 2020-02-14
	VERSION: 1.0
    #> 
    [CmdletBinding(DefaultParameterSetName="Default")]
    Param(
        [Parameter(Mandatory=$True)]
            [ValidateNotNullorEmpty()]  [string] $EnvironmentId,
        [Parameter(Mandatory=$True, ParameterSetName="ByName")]
            [ValidateNotNullorEmpty()]  [string] $Name,
        [Parameter(Mandatory=$True, ParameterSetName="ById")]
            [ValidateNotNullorEmpty()]  [string] $Id
    )
    if(!$global:VCDService.IsConnected){
        throw "You are not currently connected to the VMware Console Services Portal (CSP) for VMware Cloud Director Service. Please use Connect-VCDService cmdlet to connect to the service and try again."
    }
    # Next check if the EnvironmentId is valid
    $Environment = Get-VCDSEnvironments -Id $EnvironmentId
    if($Environment.count -eq 0){
        throw "An VCDS Environment with the Id $EnvironmentId can not be found. Please check the Id and try again."
    }

    # Setup a Service URI...need to review this after some further testing
    $ServiceURI = ($global:VCDService.CDSEnvironments | Where-Object{$_.type -eq "PRODUCTION"}).starfleetConfig.operatorURL
    # Setup a HashTable for the API call to the Cloud Gateway
    $InstancesAPIEndpoint = "$ServiceURI/environment/$EnvironmentId/instances"

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
        throw "An exception has occured attempting to make the API call. $_"
    }
}