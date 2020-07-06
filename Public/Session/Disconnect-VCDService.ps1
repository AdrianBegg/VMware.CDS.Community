function Disconnect-VCDService(){
    <#
    .SYNOPSIS
    This cmdlet removes the currently connected VMware Cloud Director service connection.
    
    .DESCRIPTION
    This cmdlet removes the currently connected VMware Cloud Director service connection.
    
    .EXAMPLE
    Disconnect-VCDSService
    Tears down the current session to the VMware Console Services Portal (CSP)
    
	.NOTES
    AUTHOR: Adrian Begg
    LASTEDIT: 2020-07-06
	VERSION: 1.1
    #>
    if(!$global:VCDService.IsConnected){
        Write-Warning "You are currently not connected to the VMware Cloud Services Portal. Nothing will be performed."
    } else {
        # Make the call to the API (TO DO) to logoff and remove the session variable from PowerShell
        try{
            # A Hashtable of Request Parameters for the Logoff
            [Hashtable] $RequestParameters = @{
                URI = "https://console.cloud.vmware.com/csp/gateway/am/api/auth/logout"
                Method = "Post"
                ContentType = "application/json"
                Headers = @{
                    "csp-auth-token" = "$($global:VCDService.RefreshToken)"
                    "Accept" = "application/json"
                }
                UseBasicParsing = $true
                Body = "{ idToken=$($global:VCDService.IdToken) }"
            }
            $CSPTokenResult = Invoke-WebRequest @RequestParameters
        } catch {
            throw "An error has occured during the logoff process."
        }
        if($CSPTokenResult.StatusCode -ne 200) {
            throw "An error has occured during the logoff process."
        }
        # Finally clear the PowerShell variable for the expired session
        Set-Variable -Name "VCDService" -Value $null -Scope Global
    }
}