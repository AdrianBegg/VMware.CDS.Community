function Set-VCDSDomain(){
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Please Note: The Instance FQDN and Console Proxy FQDN must be resolvable by public DNS before this cmdlet can be run successfully.

    .PARAMETER InstanceId
    The Cloud Director Instance Id

    .PARAMETER InstanceName
    The Cloud Director Instance Name

    .PARAMETER InstanceFQDN
    The fully-qualified domain name for the Cloud Director instance (eg. clouddirector.pigeonnuggets.com)

    .PARAMETER ConsoleProxyFQDN
    The fully-qualified domain name for the Cloud Director Console Proxy endpoint (eg. clouddirector-console.pigeonnuggets.com)

    .PARAMETER CertificateKeyPEM
    The Private Key for the Certificate in PEM format

    .PARAMETER CertificatePEM
    A string containing the full certificate chain (Certificate, Intermediate and Root CA certificates) in PEM format.

    .PARAMETER EnvironmentId
    Optionally The Cloud Director Service Environment Id (Default is used if none is provided)

    .PARAMETER Reset
    Parameter description

    .PARAMETER Async
    Parameter description

    .EXAMPLE
    An example

    .NOTES
    AUTHOR: Adrian Begg
    LASTEDIT: 2020-06-23
	VERSION: 1.0
    #>
    [CmdletBinding(DefaultParameterSetName="ByInstanceId")]
    Param(
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceId")]
            [ValidateNotNullorEmpty()]  [string] $InstanceId,
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceName")]
            [ValidateNotNullorEmpty()]  [string] $InstanceName,
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceId")]
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceName")]
            [ValidateNotNullorEmpty()]  [string] $InstanceFQDN,
            [ValidateNotNullorEmpty()]  [string] $ConsoleProxyFQDN,
            [ValidateNotNullorEmpty()]  [string] $CertificateKeyPEM,
            [ValidateNotNullorEmpty()]  [string] $CertificatePEM,
        [Parameter(Mandatory=$False, ParameterSetName="ByInstanceId")]
        [Parameter(Mandatory=$False, ParameterSetName="ByInstanceName")]
            [ValidateNotNullorEmpty()] [String] $EnvironmentId,
            [switch]$Reset,
            [switch]$Async
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
    $InstanceOperationAPIEndpoint = "$ServiceURI/environment/$($Environment.id)/instances/$($Instance.id)/operations/invoke"
    [Hashtable] $htPayload = @{
        operationType = "associateCustomDomain"
        arguments = @{}
    }

    # Set the arguments to reset the DNS and certificate settings to default
    if($PSBoundParameters.ContainsKey("Reset")){
        [Hashtable] $htArguments = @{
            revertToDefaultDomain = $true
        }
    } else {
        # Set the arguments
        [Hashtable] $htArguments = @{
            customDomainName = $InstanceFQDN
            consoleProxyCustomDomainName = $ConsoleProxyFQDN
            privateKey =
            certificates =
            revertToDefaultDomain = $null
        }
    }
    # Set the arguments to the Payload
    $htPayload.arguments = $htArguments

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
        $SetInstanceDNS = ((Invoke-WebRequest @RequestParameters).Content | ConvertFrom-Json)
        if($PSBoundParameters.ContainsKey("Async")){
            if(!(Watch-VCDSTaskCompleted -Task $SetInstanceDNS -Timeout 1800)){
                throw "An error occured executing the operation to adjust the DNS and Certificate for the instnace under task $($SetInstanceDNS) please check the console and try the operation again."
            } else {
                return (Get-VCDSTasks -Id $SetInstanceDNS.id)
            }
        } else {
            return $SetInstanceDNS
        }
    } catch {
        throw "An exception has occured attempting to make the API call. $_"
    }

}