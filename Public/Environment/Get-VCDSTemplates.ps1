function Get-VCDSTemplates(){
    <#
    .SYNOPSIS
    Returns the avaialble templates for the provided Cloud Director Service environment.
    
    .DESCRIPTION
    Returns the avaialble templates for the provided Cloud Director Service environment.
    
    .PARAMETER EnvironmentId
    The Cloud Director Service Environment Id
    
    .PARAMETER Name
    Optionally the Template Name to filter.
    
    .PARAMETER Id
    Optionally the Template Id to filter.
    
    .EXAMPLE
    Get-VCDSTemplates -EnvironmentId "urn:vcdc:environment:3fccbd2a-003c-4303-8f1a-8569853236ac"
    Returns the Templates available to the environment with the id urn:vcdc:environment:3fccbd2a-003c-4303-8f1a-8569853236ac
    
    .EXAMPLE
    Get-VCDSTemplates -EnvironmentId "urn:vcdc:environment:3fccbd2a-003c-4303-8f1a-8569853236ac" -Name "vCloud Director 10.0.0.1 RTM"
    Returns the Template with the name "vCloud Director 10.0.0.1 RTM" in the environment with the id urn:vcdc:environment:3fccbd2a-003c-4303-8f1a-8569853236ac if it exists.

	.NOTES
    AUTHOR: Adrian Begg
    LASTEDIT: 2020-02-14
	VERSION: 1.0
    #>
    [CmdletBinding(DefaultParameterSetName="Default")]
    Param(
        [Parameter(Mandatory=$True)]
            [ValidateNotNullorEmpty()]  [string] $EnvironmentId,
        [Parameter(Mandatory=$True, ParameterSetName="ByName")]
            [ValidateNotNullorEmpty()]  [string] $Name,
        [Parameter(Mandatory=$True, ParameterSetName="ById")]
            [ValidateNotNullorEmpty()]  [string] $Id
    )
    if(!$global:VCDService.IsConnected){
        throw "You are not currently connected to the VMware Console Services Portal (CSP) for VMware Cloud Director Service. Please use Connect-VCDService cmdlet to connect to the service and try again."
    }
    # Next check if the EnvironmentId is valid
    $Environment = Get-VCDSEnvironments -Id $EnvironmentId
    if($Environment.count -eq 0){
        throw "An VCDS Environment with the Id $EnvironmentId can not be found. Please check the Id and try again."
    }

    # Setup a Service URI...need to review this after some further testing
    $ServiceURI = ($global:VCDService.CDSEnvironments | Where-Object{$_.type -eq "PRODUCTION"}).starfleetConfig.operatorURL
    # Setup a HashTable for the API call to the Cloud Gateway
    $TemplateAPIEndpoint = "$ServiceURI/environment/$EnvironmentId/templates"

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
        $Templates = ((Invoke-WebRequest @RequestParameters).Content | ConvertFrom-Json)
        if($Templates.Count -eq 0){
            Write-Warning "There are no templates configured for the Cloud Director environment with Id $EnvironmentId."
        } else {
            # Check if any filters have been provided
            $Results = $Templates.values 
            if($PSBoundParameters.ContainsKey("Name")){
                $Results = $Results | Where-Object {$_.name -eq $Name}
            }
            if($PSBoundParameters.ContainsKey("Id")){
                $Results = $Results | Where-Object {$_.id -eq $Id}
            }
            return $Results
        }
    } catch {
        throw "An exception has occured attempting to make the API call. $_"
    }
}