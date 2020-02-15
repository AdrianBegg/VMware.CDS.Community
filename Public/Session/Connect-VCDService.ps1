function Connect-VCDService(){
    <#
    .SYNOPSIS
    Establishes a new connection to the VMware Cloud Director service using an API Token from the VMware Console Services Portal

    .DESCRIPTION
    Establishes a new connection to the VMware Cloud Director service using an API Token from the VMware Console Services Portal.

    If no environment is specified the first environment returned is set as the default.

    .PARAMETER CSPAPIToken
    The API Token from the VMware Console Services Portal

    .PARAMETER DefaultEnvironmentType
    The environment type (e.g. PRODUCTION)

    .PARAMETER DefaultEnvironmentName
    The Environment Name (e.g. Early Access Environment)

    .PARAMETER DefaultEnvironmentLocation
    The Environment Location (e.g. us-west-2)

    .EXAMPLE
    Connect-VCDService -CSPAPIToken "lq7hBlWsqEtp4Q7XXO4vsWm6tXwgienpXMr2wmkialrYGl7Rnyz7wUz5WuIUC4yj"
    Connects to the Cloud Director Service using a VMware Console Services Portal (CSP) token

    .EXAMPLE
    Connect-VCDService -CSPAPIToken "lq7hBlWsqEtp4Q7XXO4vsWm6tXwgienpXMr2wmkialrYGl7Rnyz7wUz5WuIUC4yj" -DefaultEnvironmentType "PRODUCTION" -DefaultEnvironmentName "Early Access Environment" -DefaultEnvironmentLocation "us-west-2"
    Connects to the Cloud Director Service using a VMware Console Services Portal (CSP) token

	.NOTES
    AUTHOR: Adrian Begg
    LASTEDIT: 2020-02-15
	VERSION: 1.0
    #>
    [CmdletBinding(DefaultParameterSetName="Default")]
    Param (
        [Parameter(Mandatory=$True, ParameterSetName="Default")]
        [Parameter(Mandatory=$True, ParameterSetName="DefaultEnvironmentSet")]
            [String] $CSPAPIToken,
        [Parameter(Mandatory=$True, ParameterSetName="DefaultEnvironmentSet")]
            [String] $DefaultEnvironmentName,
        [Parameter(Mandatory=$True, ParameterSetName="DefaultEnvironmentSet")]
            [String] $DefaultEnvironmentType,
        [Parameter(Mandatory=$True, ParameterSetName="DefaultEnvironmentSet")]
            [String] $DefaultEnvironmentLocation
    )
    if($global:VCDSService.IsConnected){
        Write-Warning "You are already connected to the CSP Service. Your existing session will be disconnected if you continue." -WarningAction Inquire
        Disconnect-VCDService
    }
    # First Generate a Bearer Token
    try{
        $CSPTokenResult = Invoke-WebRequest -Uri "https://console.cloud.vmware.com/csp/gateway/am/api/auth/api-tokens/authorize" -Method POST -Headers @{accept='application/json'} -Body "refresh_token=$CSPAPIToken"
    } catch {
        throw "Failed to retrieve Access Token, please ensure your VMC Refresh Token is valid and try again"
    }
    if($CSPTokenResult.StatusCode -ne 200) {
        throw "Failed to retrieve Access Token, please ensure your VMC Refresh Token is valid and try again"
    }
    $BearerToken = ($CSPTokenResult | ConvertFrom-Json).access_token
    $RefreshToken = ($CSPTokenResult | ConvertFrom-Json).refresh_token

    # Create a Connection object and populate with available environments
    $objVCDCConnection = New-Object System.Management.Automation.PSObject
    $objVCDCConnection | Add-Member Note* AccessToken $BearerToken
    $objVCDCConnection | Add-Member Note* RefreshToken $RefreshToken
    $objVCDCConnection | Add-Member Note* IsConnected $true

    # Next make a call to the VCD Cloud Gateway to return a collection of Environment Types available
    $VCDCSPGatewayEnvAPIEndpoint = "https://gateway.vcd.cloud.vmware.com/environment.json"
    # A Hashtable of Request Parameters
    [Hashtable] $VCDCSPEnvRequestParameters = @{
        URI = $VCDCSPGatewayEnvAPIEndpoint
        Method = "Get"
        ContentType = "application/json"
        Headers = @{"csp-auth-token"="$BearerToken"}
        UseBasicParsing = $true
    }
    $VCDCSPGatewayEnv = (Invoke-WebRequest @VCDCSPEnvRequestParameters).Content | ConvertFrom-Json
    if($VCDCSPGatewayEnv.Count -eq 0){
            throw "The account does not have access to any Cloud Director environments. Please check the permissions and try again."
    }

    # Next query each VCD Cloud Gateway environment for the VCDS Environments and build a collection
    $VCDSEnvironments = New-Object -TypeName "System.Collections.ArrayList"
    foreach($VCDSEnv in $VCDCSPGatewayEnv){
        # Setup a Service URI for the API Call
        $VCDSEnvAPIEndpoint = "$($VCDSEnv.starfleetConfig.operatorURL)/environments"
        # A Hashtable of Request Parameters
        [Hashtable] $VCDSEnvRequestParameters = @{
            URI = $VCDSEnvAPIEndpoint
            Method = "Get"
            ContentType = "application/json"
            Headers = @{
                "Authorization" = "Bearer $BearerToken"
                "Accept" = "application/json"
            }
            UseBasicParsing = $true
        }
        # Get the accessible environments
        $AccessibleEnvironments = ((Invoke-WebRequest @VCDSEnvRequestParameters).Content | ConvertFrom-Json).values
        if($AccessibleEnvironments.Count -eq 0){
            Write-Warning "The account does not have access to any Cloud Director environments under the environment $($Environment.type) $($Environment.starfleetConfig.operatorURL)."
        }
        # Add some metadata to the Environments (messy structure) to make them easier to work with
        $AccessibleEnvironments | Add-Member Note* type $VCDSEnv.type
        $AccessibleEnvironments | Add-Member Note* ServiceURI $VCDSEnv.starfleetConfig.operatorUrl
        $VCDSEnvironments.Add($AccessibleEnvironments) | Out-Null
    }
    # Add the Available environments to the connection object
    $objVCDCConnection | Add-Member Note* VCDSEnvironments $VCDSEnvironments

    # Next determine the default and add the collection to the VCDService Global
    if($PSCmdlet.ParameterSetName -eq "DefaultEnvironmentSet") {
        $DefaultEnvironment = $VCDSEnvironments | Where-Object {($_.name -eq $DefaultEnvironmentName) -and ($_.Location -eq $DefaultEnvironmentLocation) -and ($_.type -eq $DefaultEnvironmentType)}
        if($DefaultEnvironment.Count -eq 0){
            throw "A default environment with the provided parameters can not be found or you do not have permission to it."
        } else {
            $objVCDCConnection | Add-Member Note* DefaultEnvironment $DefaultEnvironment
        }
    } else {
        $objVCDCConnection | Add-Member Note* DefaultEnvironment $VCDSEnvironments[0]
    }

    # Finally set the connection object
    Set-Variable -Name "VCDService" -Value $objVCDCConnection -Scope Global
}