function Get-VCDSEnvironments(){
    <#
    .SYNOPSIS
    Returns the Cloud Director Service environments for the default CSP environment on the currently available under the currently connected VMware Console Services Portal account.

    .DESCRIPTION
    Returns the Cloud Director Service environments for the default CSP environment on the currently available under the currently connected VMware Console Services Portal account.

    .PARAMETER Name
    The Name of the Environment to filter results by

    .PARAMETER Id
    The Environment unique identifier to filter results by

    .PARAMETER Location
    Optionally the Amazon Region to filter results by (e.g. us-west2)

    .EXAMPLE
    Get-VCDSEnvironments
    Returns all of the environments available to the currently connected user.

    .EXAMPLE
    Get-VCDSEnvironments -Location "us-west-2"
    Returns all environments in the region US-West-2

    .EXAMPLE
    Get-VCDSEnvironments -Name "Early Access Environment"
    Returns all environments with the Name "Early Access Environment"

	.NOTES
    AUTHOR: Adrian Begg
    LASTEDIT: 2020-02-14
	VERSION: 1.0
    #>
    [CmdletBinding(DefaultParameterSetName="Default")]
    Param(
        [Parameter(Mandatory=$True, ParameterSetName="ByName")]
            [ValidateNotNullorEmpty()]  [string] $Name,
        [Parameter(Mandatory=$True, ParameterSetName="ById")]
            [ValidateNotNullorEmpty()]  [string] $Id,
        [Parameter(Mandatory=$False, ParameterSetName="ByName")]
        [Parameter(Mandatory=$True, ParameterSetName="ByLocation")]
            [ValidateNotNullorEmpty()]  [string] $Location
    )
    if(!$global:VCDService.IsConnected){
        throw "You are not currently connected to the VMware Console Services Portal (CSP) for VMware Cloud Director Service. Please use Connect-VCDService cmdlet to connect to the service and try again."
    }
    # Setup a Service URI...need to review this after some further testing
    $ServiceURI = $VCDService.DefaultEnvironment.url
    # Setup a HashTable for the API call to the Cloud Gateway
    $EnvironmentAPIEndpoint = "$ServiceURI/organizations/$($VCDService.OrganizationId)/environments"

    # A Hashtable of Request Parameters
    [Hashtable] $RequestParameters = @{
        URI = $EnvironmentAPIEndpoint
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
        $Environments = ((Invoke-WebRequest @RequestParameters).Content | ConvertFrom-Json)
        if($Environments.Count -eq 0){
            Write-Warning "The account does not have access to any Cloud Director environments."
        } else {
            # Check if any filters have been provided
            $Results = $Environments.values
            if($PSBoundParameters.ContainsKey("Name")){
                $Results = $Results | Where-Object {$_.name -eq $Name}
            }
            if($PSBoundParameters.ContainsKey("Id")){
                $Results = $Results | Where-Object {$_.id -eq $Id}
            }
            if($PSBoundParameters.ContainsKey("Location")){
                $Results = $Results | Where-Object {$_.Location -eq $Location}
            }
            return $Results
        }
    } catch {
        throw "An exception has occurred attempting to make the API call. $_"
    }
}