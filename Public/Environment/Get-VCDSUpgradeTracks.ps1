function Get-VCDSUpgradeTracks(){
    <#
    .SYNOPSIS
    Returns the configurable upgrade tracks and stations for the provided Cloud Director Service environment.

    .DESCRIPTION
    Returns the configurable upgrade tracks and stations for the provided Cloud Director Service environment.

    .PARAMETER EnvironmentId
    Optionally The Cloud Director Service Environment Id (Default is used if none is provided)

    .PARAMETER TrackName
    Optionally the Upgrade Track to filter.

    .PARAMETER StationName
    Optionally the Station Name to filter.

    .PARAMETER DefaultStation
    If set returns the deafult station for the provided environment

    .EXAMPLE
    Get-VCDSUpgradeTracks
    Returns a collection of all upgrade tracks and stations available for the default environment

    .EXAMPLE
    Get-VCDSUpgradeTracks -DefaultStation
    Returns the default station for the current

    .EXAMPLE
    Get-VCDSUpgradeTracks -EnvironmentId "urn:vcdc:environment:3fccbd2a-003c-4303-8f1a-8569853236ac" -TrackName "sp-main"
    Returns all of the stations under the Upgrade Track named "sp-main" in the environment with the id urn:vcdc:environment:3fccbd2a-003c-4303-8f1a-8569853236ac if it exists.

	.NOTES
    AUTHOR: Adrian Begg
    LASTEDIT: 2020-11-17
	VERSION: 1.0
    #>
    [CmdletBinding(DefaultParameterSetName="Default")]
    Param(
        [Parameter(Mandatory=$True, ParameterSetName="TrackName")]
            [ValidateNotNullorEmpty()]  [string] $TrackName,
        [Parameter(Mandatory=$True, ParameterSetName="StationName")]
            [ValidateNotNullorEmpty()]  [string] $StationName,
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()]  [string] $EnvironmentId,
        [Parameter(Mandatory=$False, ParameterSetName="Default")]
            [switch]$DefaultStation
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

    # Setup a HashTable for the API call to the Cloud Gateway
    $TemplateAPIEndpoint = "$ServiceURI/environment/$($Environment.id)/upgrade-tracks-and-stations"

    # A Hashtable of Request Parameters
    [Hashtable] $RequestParameters = @{
        URI = $TemplateAPIEndpoint
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
        $colUpgradeTracks = ((Invoke-WebRequest @RequestParameters).Content | ConvertFrom-Json)
        if($DefaultStation){
            return $colUpgradeTracks.defaultStation
        } else {
            if($PSBoundParameters.ContainsKey("TrackName")){
                return $colUpgradeTracks.tracks | Where-Object {$_.name -eq $TrackName}
            }
            elseif($PSBoundParameters.ContainsKey("StationName")){
                foreach($Station in $colUpgradeTracks.tracks.stations){
                    if($Station -eq $StationName){
                        return $StationName
                    }
                }
            } else {
                return $colUpgradeTracks.tracks
            }
        }
    } catch {
        throw "An exception has occurred attempting to make the API call. $_"
    }
}