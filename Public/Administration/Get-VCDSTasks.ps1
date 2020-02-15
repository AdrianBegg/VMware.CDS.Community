function Get-VCDSTasks(){
    <#
    .SYNOPSIS
    Returns a collection of Tasks from the connected Cloud Director Service environment.
    
    .DESCRIPTION
    Returns a collection of Tasks from the connected Cloud Director Service environment.
    
    .PARAMETER EnvironmentId
    The Cloud Director Service Environment Id
    
    .PARAMETER Id
    The Cloud Director Service Task Id to filter the Tasks.
    
    .PARAMETER EntityId
    The Cloud Director Service Entity Id to filter the Tasks.
    
    .PARAMETER EventStatus
    The status to filter the events.
    
    .PARAMETER UserId
    The UserId to filter the events.
    
    .EXAMPLE
    Get-VCDSTasks -EnvironmentId "urn:vcdc:environment:3fccbd2a-003c-4303-8f1a-8569853236ac"
    Returns the VCDS tasks for the Environment with the Id "urn:vcdc:environment:3fccbd2a-003c-4303-8f1a-8569853236ac"
 
	.NOTES
    AUTHOR: Adrian Begg
    LASTEDIT: 2020-02-14
	VERSION: 1.0
    #> 
    Param(
        [Parameter(Mandatory=$True)]
            [ValidateNotNullorEmpty()] [String]  $EnvironmentId,
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()] [String] $Id,
            [ValidateNotNullorEmpty()] [String] $EntityId,
            [ValidateSet("SUCCESS","FAILURE")] [String] $EventStatus,
            [ValidateNotNullorEmpty()] [String] $Organisation,
            [ValidateNotNullorEmpty()] [String] $UserId
    )
    if(!$global:VCDService.IsConnected){
        throw "You are not currently connected to the VMware Console Services Portal (CSP) for VMware Cloud Director Service. Please use Connect-VCDService cmdlet to connect to the service and try again."
    }
    # Next check if the EnvironmentId is valid
    $Environment = Get-VCDSEnvironments -Id $EnvironmentId
    if($Environment.count -eq 0){
        throw "An VCDS Environment with the Id $EnvironmentId can not be found. Please check the Id and try again."
    }
    # A collection of filters
    [Hashtable] $htFilters = @{
        sort = "asc"
        page = 1
        limit = 100
    }
    throw "Currently the page filter does not function - the cmdlet does not function."
    # Setup a Service URI...need to review this after some further testing
    $ServiceURI = ($global:VCDService.CDSEnvironments | Where-Object{$_.type -eq "PRODUCTION"}).starfleetConfig.operatorURL
    # Setup a HashTable for the API call to the Cloud Gateway
    $TasksAPIEndpoint = "$ServiceURI/environment/$EnvironmentId/tasks"

    # A Hashtable of Request Parameters
    [Hashtable] $RequestParameters = @{
        URI = $TasksAPIEndpoint
        Method = "Get"
        ContentType = "application/json"
        Headers = @{
            "Authorization" = "Bearer $($global:VCDService.AccessToken)"
            "Accept" = "application/json"
        }
        UseBasicParsing = $true
        Body = $htFilters
    }
    # Now make an inital call to the API
    $Response =  ((Invoke-WebRequest @RequestParameters).Content | ConvertFrom-Json)
    # Add the inital tasks from the first API call to a collection
    $colTasks = $Response.values

    # Iterate over the results to retrieve all tasks
    if($Response.pageCount -ne 0){
        while ($Response.pageCount -gt $Response.page){
            # Increment to the next page and add the results
            ($htFilters.page)++ | Out-Null
            $RequestParameters.Body = $htFilters
            $Response = ((Invoke-WebRequest @RequestParameters).Content | ConvertFrom-Json)
            $colTasks += $Response.values
        }
    }
    # Finally post call filters (TO DO)
    return $colTasks
}