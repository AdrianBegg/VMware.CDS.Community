function Set-VCDSDomain(){
    <#
    .SYNOPSIS
    Configures a Custom DNS name and X.509 SSL certificates for a Cloud Director service instance and Console Proxy endpoints.

    .DESCRIPTION
    Configures a Custom DNS name and X.509 SSL certificates for a Cloud Director service instance and Console Proxy endpoints.

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
    If this switch is provided the custom DNS and certificates are cleared and the defaults created at instance creation are restored.

    .PARAMETER Async
    If this switch is provided execution will occur asynchronously

    .EXAMPLE
    Set-VCDSDomain -InstanceName "CloudDirector-TestInstance-01" -Reset
    Resets the certificate and DNS configuration for the instance named "CloudDirector-TestInstance-01" to the default (Clears any custom configuration)

    .EXAMPLE
    Set-VCDSDomain -InstanceName "CloudDirector-TestInstance-01" -InstanceFQDN "clouddirector.pigeonnuggets.com" -ConsoleProxyFQDN "clouddirector-console.pigeonnuggets.com" -CertificateKeyPEM (Get-Content C:\Certbot\live\pigeonnuggets.com\privkey.pem -Raw) -CertificatePEM (Get-Content C:\Certbot\live\pigeonnuggets.com\fullchain.pem -Raw)
    Sets a custom domain of "clouddirector.pigeonnuggets.com" for the CDS instance with the name "CloudDirector-TestInstance-01" using the TLS Certificate in C:\Certbot\live\pigeonnuggets.com\fullchain.pem and the private key named privkey.pem and sets the console proxy address to "clouddirector-console.pigeonnuggets.com"

    .NOTES
    AUTHOR: Adrian Begg
    LASTEDIT: 2020-07-07
	VERSION: 1.1
    #>
    [CmdletBinding(DefaultParameterSetName="ByInstanceId")]
    Param(
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceId")]
            [ValidateNotNullorEmpty()]  [string] $InstanceId,
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceName")]
        [Parameter(Mandatory=$True, ParameterSetName="Reset")]
            [ValidateNotNullorEmpty()]  [string] $InstanceName,
        [Parameter(Mandatory=$True, ParameterSetName="Reset")]
            [switch]$Reset,
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceId")]
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceName")]
            [ValidateNotNullorEmpty()]  [string] $InstanceFQDN,
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceId")]
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceName")]
            [ValidateNotNullorEmpty()]  [string] $ConsoleProxyFQDN,
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceId")]
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceName")]
            [ValidateNotNullorEmpty()]  [string] $CertificateKeyPEM,
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceId")]
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceName")]
            [ValidateNotNullorEmpty()]  [string] $CertificatePEM,
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()] [String] $EnvironmentId,
        [Parameter(Mandatory=$False)]
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
    $ServiceURI = $Environment.url

    if($PSCmdlet.ParameterSetName -in ("ByInstanceName","Reset")) {
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

    # Setup a HashTable for the API call to the Cloud Gateway and the default operation type (Set Custom Domain)
    $InstanceOperationAPIEndpoint = "$ServiceURI/environment/$($Environment.id)/instances/$($Instance.id)/operations/invokeOperation"
    [Hashtable] $htPayload = @{
        operationType = "PLAIN_CUSTOM_DOMAIN"
        arguments = @{}
    }

    # Set the arguments to reset the DNS and certificate settings to default
    if($PSBoundParameters.ContainsKey("Reset")){
        $htPayload.operationType = "REVERT_CUSTOM_DOMAIN"
    } else {
        # Set the arguments
        [Hashtable] $htArguments = @{
            customDomainName = $InstanceFQDN
            consoleProxyCustomDomainName = $ConsoleProxyFQDN
            privateKey = $CertificateKeyPEM
            certificates = $CertificatePEM
        }
        # Set the arguments to the Payload
        $htPayload.arguments = $htArguments
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
        $SetInstanceDNS = ((Invoke-WebRequest @RequestParameters).Content | ConvertFrom-Json)
        if($PSBoundParameters.ContainsKey("Async")){
            if(!(Watch-VCDSTaskCompleted -Task $SetInstanceDNS -Timeout 1800)){
                throw "An error occurred executing the operation to adjust the DNS and Certificate for the instnace under task $($SetInstanceDNS) please check the console and try the operation again."
            } else {
                return (Get-VCDSTasks -Id $SetInstanceDNS.id)
            }
        } else {
            return $SetInstanceDNS
        }
    } catch {
        throw "An exception has occurred attempting to make the API call. $_"
    }
}