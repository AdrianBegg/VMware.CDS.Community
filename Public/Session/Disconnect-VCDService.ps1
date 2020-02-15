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
    LASTEDIT: 2020-02-14
	VERSION: 1.0
    #>
    if(!$global:VCDService.IsConnected){
        Write-Warning "You are currently not connected to the VMware Cloud Services Portal. Nothing will be performed."
    } else {
        # Make the call to the API (TO DO) to logoff and remove the session variable from PowerShell
        Set-Variable -Name "VCDService" -Value $null -Scope Global
    }
}