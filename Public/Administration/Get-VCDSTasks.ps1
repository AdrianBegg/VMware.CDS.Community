function Get-VCDSTasks(){
    <#
    .SYNOPSIS
    Returns a collection of Tasks from the connected Cloud Director Service environment.

    .DESCRIPTION
    Returns a collection of Tasks from the connected Cloud Director Service environment.

    .PARAMETER EnvironmentId
    Optionally the Cloud Director Service Environment Id (the default is used if none is provided)

    .PARAMETER Id
    The Cloud Director service Task Id to filter the Tasks.

    .PARAMETER EntityId
    The Cloud Director service Entity Id to filter the Tasks.

    .PARAMETER TaskName
    The Cloud Director service Task Name to filter the Tasks by.

    .PARAMETER EventStatus
    The status to filter the events.

    .PARAMETER UserId
    The UserId to filter the events.

    .PARAMETER IncludeFiles
    If true returns the details of any files associated with the Task (e.g. Support Bundles)

    .EXAMPLE
    Get-VCDSTasks
    Returns the VCDS tasks for default environment.

    .EXAMPLE
    Get-VCDSTasks -EnvironmentId "urn:vcdc:environment:3fccbd2a-003c-4303-8f1a-8569853236ac"
    Returns the VCDS tasks for the Environment with the Id "urn:vcdc:environment:3fccbd2a-003c-4303-8f1a-8569853236ac"

    .EXAMPLE
    Get-VCDSTasks -EntityId urn:vcdc:vcdInstance:35cdd922-dae7-415f-bbef-d333ac5573d9 -EventStatus "Failed"
    Returns all of the VCDS tasks for the Entity "urn:vcdc:vcdInstance:35cdd922-dae7-415f-bbef-d333ac5573d9" that have a status of failed.

    .EXAMPLE
    Get-VCDSTasks -TaskName "createSupportBundle"
    Returns all of the VCDS tasks with the Task Name "createSupportBundle"

	.NOTES
    AUTHOR: Adrian Begg
    LASTEDIT: 2020-07-07
	VERSION: 1.2
    #>
    Param(
        [Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()] [String] $Id,
            [ValidateNotNullorEmpty()] [String] $TaskName,
            [ValidateNotNullorEmpty()] [String] $EntityId,
            [ValidateSet("SUCCESS","IN_PROGRESS","FAILED")] [String] $EventStatus,
            [ValidateNotNullorEmpty()] [String] $UserId,
            [ValidateNotNullorEmpty()] [String]  $EnvironmentId,
            [switch] $IncludeFiles
    )
    # TO DO : Implement filtering on the Task Properties
    # TO DO : Pending security fix from VMware (currently can see all tasks), adjust the URI to use the Organization Id instead of just environment Id
    if(!$global:VCDService.IsConnected){
        throw "You are not currently connected to the VMware Cloud Services Portal (CSP) for VMware Cloud Director Service. Please use Connect-VCDService cmdlet to connect to the service and try again."
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

    # A collection of filters
    [Hashtable] $htFilters = @{
        sortBy = "queuedTime"
        sortDir = "desc"
        page = 1
        limit = 100
    }

    # Setup a HashTable for the API call to the Cloud Gateway
    $TasksAPIEndpoint = "$ServiceURI/environment/$($Environment.id)/organization/$($VCDService.OrganizationId)/tasks"

    # Setup the URI for a single Task
    if($PSBoundParameters.ContainsKey("Id")){
        $TasksAPIEndpoint = "$ServiceURI/environment/$($Environment.id)/tasks/$Id"
    }

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
    # Now make an initial call to the API
    $Response =  ((Invoke-WebRequest @RequestParameters).Content | ConvertFrom-Json)
    # Check if single result or multiple results
    if($PSBoundParameters.ContainsKey("Id")){
        $colTasks = $Response
    } else {
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
    }
    # Next check if the -IncludeFiles flag was provided for the task
    if ($PSBoundParameters.ContainsKey("IncludeFiles")) {
        # Iterate through all tasks and add any files to the object
        foreach($objTask in $colTasks){
            # Construct the URI
            $TaskFilesURI = "$TasksAPIEndpoint/${$objTask.id}files"
            # A Hashtable of Request Parameters
            [Hashtable] $FileRequestParameters = @{
                URI = $TaskFilesURI
                Method = "Get"
                ContentType = "application/json"
                Headers = @{
                    "Authorization" = "Bearer $($global:VCDService.AccessToken)"
                    "Accept" = "application/json"
                }
                UseBasicParsing = $true
            }
            # Now make an initial call to the API
            $FilesResponse =  ((Invoke-WebRequest @FileRequestParameters).Content | ConvertFrom-Json)
            # Check if anything was returned
            if($FilesResponse.Count -gt 0){
                # Add the files to the task object
                $objTask | Add-Member Note* files $FilesResponse
            }
        }
    }
    # Finally post call filters
    if($PSBoundParameters.ContainsKey("EntityId")){
        $colTasks = $colTasks | Where-Object{$_.entityId -eq $EntityId}
    }
    if($PSBoundParameters.ContainsKey("EventStatus")){
        $colTasks = $colTasks | Where-Object{$_.status -eq $EventStatus}
    }
    if($PSBoundParameters.ContainsKey("UserId")){
        $colTasks = $colTasks | Where-Object{$_.UserId -eq $UserId}
    }
    if($PSBoundParameters.ContainsKey("TaskName")){
        $colTasks = $colTasks | Where-Object{$_.name -eq $TaskName}
    }
    return $colTasks
}