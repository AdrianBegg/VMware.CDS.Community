function Register-VCDSSDDC(){
    <#
    .SYNOPSIS
    Associate an VMC SDDC with a VMware Cloud Director service instance.

    .DESCRIPTION
    Associate an VMC SDDC with a VMware Cloud Director service instance.

    .PARAMETER EnvironmentId
    Optionally the Cloud Director Service Environment Id (the default is used if none is provided)

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

    .PARAMETER UseVMCProxy
    If provided will Associate a VMC SDDC via Proxy

    .EXAMPLE
    Register-VCDSSDDC -EnvironmentId "urn:vcdc:environment:3fccbd2a-003c-4303-8f1a-8569853236ac" -InstanceName "CDS-Instance-01" -VMCOrganisationUUID "398712a64b-5462-21e4-b4e1-29b0452ac82d" -SDDCName "CDS-Dev-SDDC-01" -VMCAPIToken "ATduasdE1kBpsajdasdRF0HgFtA22jKazpmu4KXdIES1J2esGuwWKYmDpT4OIpNA"
    Registers the VMC SDDC named "CDS-Dev-SDDC-01" in Org with UUID "398712a64b-5462-21e4-b4e1-29b0452ac82d" to the CDS instance named CDS-Instance-01 in the environment with the Id "urn:vcdc:environment:3fccbd2a-003c-4303-8f1a-8569853236ac"

    .EXAMPLE
    Register-VCDSSDDC -UseVMCProxy -EnvironmentId "urn:vcdc:environment:3fccbd2a-003c-4303-8f1a-8569853236ac" -InstanceName "CDS-Instance-01" -VMCOrganisationUUID "398712a64b-5462-21e4-b4e1-29b0452ac82d" -SDDCName "CDS-Dev-SDDC-01" -VMCAPIToken "ATduasdE1kBpsajdasdRF0HgFtA22jKazpmu4KXdIES1J2esGuwWKYmDpT4OIpNA"
    Uses the VMC Proxy to register the VMC SDDC named "CDS-Dev-SDDC-01" in Org with UUID "398712a64b-5462-21e4-b4e1-29b0452ac82d" to the CDS instance named CDS-Instance-01 in the environment with the Id "urn:vcdc:environment:3fccbd2a-003c-4303-8f1a-8569853236ac"

    .NOTES
    AUTHOR: Adrian Begg
    LASTEDIT: 2020-11-17
	VERSION: 2.0
    #>
    [CmdletBinding(DefaultParameterSetName="ByInstanceId")]
    Param(
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceId")]
            [ValidateNotNullorEmpty()]  [string] $InstanceId,
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceName")]
            [ValidateNotNullorEmpty()]  [string] $InstanceName,
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceId")]
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceName")]
            [ValidateNotNullorEmpty()]  [string] $VMCOrganisationUUID,
            [ValidateNotNullorEmpty()]  [string] $VMCAPIToken,
            [ValidateNotNullorEmpty()]  [string] $SDDCName,
        [Parameter(Mandatory=$False, ParameterSetName="ByInstanceId")]
        [Parameter(Mandatory=$False, ParameterSetName="ByInstanceName")]
            [ValidateNotNullorEmpty()] [String] $EnvironmentId,
        [Parameter(Mandatory=$False)]
            [switch]$UseVMCProxy
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
    $InstanceOperationAPIEndpoint = "$ServiceURI/environment/$($Environment.id)/instances/$($Instance.id)/operations/invokeOperation"
    [Hashtable] $htPayload = @{
        operationType = "REGISTER_VMC"
        arguments = @{
            apiToken = $VMCAPIToken
            vmcCspOrgId = $VMCOrganisationUUID
            vmcName = $SDDCName
        }
    }
    # Check if the "-UseVMCProxy" switch has been provided
    if($UseVMCProxy){
        Write-Warning "The -UseVMCProxy option is not currently implemented in Cloud Director service. This switch currently has no effect."
        #$htPayload.operationType = "associateVmcViaProxy"
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
        throw "An exception has occurred attempting to make the API call. $_"
    }
}