function Connect-VCDService(){
    <#
    .SYNOPSIS
    Establishes a new connection to the VMware Cloud Director service using an API Token from the VMware Console Services Portal
    
    .DESCRIPTION
    Establishes a new connection to the VMware Cloud Director service using an API Token from the VMware Console Services Portal
    
    .PARAMETER CSPAPIToken
    The API Token from the VMware Console Services Portal
    
    .EXAMPLE
    Connect-VCDService -CSPAPIToken "lq7hBlWsqEtp4Q7XXO4vsWm6tXwgienpXMr2wmkialrYGl7Rnyz7wUz5WuIUC4yj"
    Connects to the Cloud Director Service using a VMware Console Services Portal (CSP) token
    
	.NOTES
    AUTHOR: Adrian Begg
    LASTEDIT: 2020-02-14
	VERSION: 1.0
    #>
    Param (
        [Parameter(Mandatory=$true)] 
            [String] $CSPAPIToken
    )
    if($global:VCDSService.IsConnected){
        Write-Warning "You are already connected to the CSP Service. Your existing session will be disconnected if you continue." -WarningAction Inquire
        Disconnect-VCDService
    }
   # First Generate a Bearer Token 
    $CSPTokenResult = Invoke-WebRequest -Uri "https://console.cloud.vmware.com/csp/gateway/am/api/auth/api-tokens/authorize" -Method POST -Headers @{accept='application/json'} -Body "refresh_token=$CSPAPIToken"
    if($CSPTokenResult.StatusCode -ne 200) {
        throw "Failed to retrieve Access Token, please ensure your VMC Refresh Token is valid and try again"
    }
    $BearerToken = ($CSPTokenResult | ConvertFrom-Json).access_token
    $RefreshToken = ($CSPTokenResult | ConvertFrom-Json).refresh_token

    # Next make a call to the VCD Cloud Gateway to return a collection of environments
    $EnvironmentAPIEndpoint = "https://gateway.vcd.cloud.vmware.com/environment.json"
    # A Hashtable of Request Parameters
    [Hashtable] $EnvRequestParameters = @{
        URI = $EnvironmentAPIEndpoint
        Method = "Get"
        ContentType = "application/json"
        Headers = @{"csp-auth-token"="$BearerToken"}
        UseBasicParsing = $true
    }
    $AvailableEnvironments = (Invoke-WebRequest @EnvRequestParameters).Content | ConvertFrom-Json
    if($AvailableEnvironments.Count -eq 0){
            throw "The account does not have access to any Cloud Director environments. Please check the permissions and try again."
    }
    # Create a Connection object and populate with available environments
    $objVCDCConnection = New-Object System.Management.Automation.PSObject
    $objVCDCConnection | Add-Member Note* AccessToken $BearerToken
    $objVCDCConnection | Add-Member Note* RefreshToken $RefreshToken
    $objVCDCConnection | Add-Member Note* IsConnected $true
    $objVCDCConnection | Add-Member Note* CDSEnvironments ($AvailableEnvironments | Select-Object type,starfleetConfig)
    Set-Variable -Name "VCDService" -Value $objVCDCConnection -Scope Global
}