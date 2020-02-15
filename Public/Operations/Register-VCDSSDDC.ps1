function Register-VCDSSDDC(){
    <#
    .SYNOPSIS
    Associate an VMC SDDC with a VMware Cloud Director service instance.

    .DESCRIPTION
    Associate an VMC SDDC with a VMware Cloud Director service instance.

    .PARAMETER EnvironmentId
    The environment Id for the VMware Cloud Director service

    .PARAMETER InstanceId
    The VMware Cloud Director service instance id

    .PARAMETER InstanceName
    The VMware Cloud Director service instance name

    .PARAMETER VMCOrganisationUUID
    The long name (UUID format) for the CSP organization containing your VMCs.

    .PARAMETER VMCAPIToken
    An API token with appropriate permissions from the CSP organization containing your VMC.

    .PARAMETER SDDCName
    The name of the VMC you would like to associate with Cloud Director Service.

    .EXAMPLE
    Register-VCDSSDDC -EnvironmentId "urn:vcdc:environment:3fccbd2a-003c-4303-8f1a-8569853236ac" -InstanceName "CDS-Instance-02" -VMCOrganisationUUID "398712a64b-5462-21e4-b4e1-29b0452ac82d" -SDDCName "CDS-Dev-SDDC-01" -VMCAPIToken "ATduasdE1kBpNS7RF0HgFtA22jKazpmu4KXdIES1J2esGuwWKYmDpT4OIpNA"
    Registers the VMC SDDC named "CDS-Dev-SDDC-01" in Org with UUID "398712a64b-5462-21e4-b4e1-29b0452ac82d" to the CDS instance named CDS-Instance-02 in the environment with the Id "urn:vcdc:environment:3fccbd2a-003c-4303-8f1a-8569853236ac"

    .NOTES
    AUTHOR: Adrian Begg
    LASTEDIT: 2020-02-14
	VERSION: 1.0
    #> 
    [CmdletBinding(DefaultParameterSetName="ById")]
    Param(
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceId")]
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceName")]
            [ValidateNotNullorEmpty()] [String] $EnvironmentId,
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceId")]
            [ValidateNotNullorEmpty()]  [string] $InstanceId,
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceName")]
            [ValidateNotNullorEmpty()]  [string] $InstanceName,
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceId")]
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceName")]
            [ValidateNotNullorEmpty()]  [string] $VMCOrganisationUUID,
            [ValidateNotNullorEmpty()]  [string] $VMCAPIToken,
            [ValidateNotNullorEmpty()]  [string] $SDDCName
    )
    if(!$global:VCDService.IsConnected){
        throw "You are not currently connected to the VMware Console Services Portal (CSP) for VMware Cloud Director Service. Please use Connect-VCDService cmdlet to connect to the service and try again."
    }
    # Next check if the EnvironmentId is valid
    $Environment = Get-VCDSEnvironments -Id $EnvironmentId
    if($Environment.count -eq 0){
        throw "An VCDS Environment with the Id $EnvironmentId can not be found. Please check the Id and try again."
    }
    if($PSCmdlet.ParameterSetName -eq "ByName") {
        # Check if an instance already exists with the provided Name
        $Instance = Get-VCDSInstance -EnvironmentId $EnvironmentId -Name $Name
        if($Instance.count -eq 0){
            throw "An instance with the Name $Name can not be found in the environment with the Id $EnvironmentId please check the Name and try again."
        }
    }
    if($PSCmdlet.ParameterSetName -eq "ById") {
        # Check if an instance already exists with the provided Id
        $Instance = Get-VCDSInstance -EnvironmentId $EnvironmentId -Id $Id
        if($Instance.count -eq 0){
            throw "An instance with the Id $Id can not be found in the environment with the Id $EnvironmentId please check the Name and try again."
        }
    }
    # Setup a Service URI...need to review this after some further testing
    $ServiceURI = ($global:VCDService.CDSEnvironments | Where-Object{$_.type -eq "PRODUCTION"}).starfleetConfig.operatorURL
    # Setup a HashTable for the API call to the Cloud Gateway
    $InstanceOperationAPIEndpoint = "$ServiceURI/environment/$EnvironmentId/instances/$($Instance.id)/operations/invoke"
    [Hashtable] $htPayload = @{
        operationType = "associateVmc"
        arguments = @{
            apiToken = $VMCAPIToken
            vmcCspOrgId = $VMCOrganisationUUID
            vmcName = $SDDCName
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
        $CreateInstanceResult = ((Invoke-WebRequest @RequestParameters).Content | ConvertFrom-Json)
        return $CreateInstanceResult
    } catch {
        throw "An exception has occured attempting to make the API call. $_"
    }
}