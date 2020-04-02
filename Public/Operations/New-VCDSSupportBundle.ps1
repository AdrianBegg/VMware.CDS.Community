function New-VCDSSupportBundle(){
    <#
    .SYNOPSIS
    Generate a new Cloud Director support bundle. This operation requires administrative permissions and may take a while.

    .DESCRIPTION
    Generate a new Cloud Director support bundle. This operation requires administrative permissions and may take a while.

    .PARAMETER Download
    If the parameter is set to $true after the support bundle has been generated it will be download to the current working directory

    .EXAMPLE
    New-VCDSSupportBundle -InstanceName "CDS-Instance-01"
    Generates a new Cloud Director support bundle for the instance with the name "CDS-Instance-01" and returns the details of the support bundle object generated.

    .EXAMPLE
    New-VCDSSupportBundle -Download
    Generates a new Cloud Director support bundle and downloads the buddle files to the current working directory.

    .NOTES
    AUTHOR: Adrian Begg
	LASTEDIT: 2020-04-02
	VERSION: 1.0
    #>
    [CmdletBinding(DefaultParameterSetName="ByInstanceId")]
    Param(
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceId")]
            [ValidateNotNullorEmpty()]  [string] $InstanceId,
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceName")]
            [ValidateNotNullorEmpty()]  [string] $InstanceName,
        [Parameter(Mandatory=$False, ParameterSetName="ByInstanceId")]
        [Parameter(Mandatory=$False, ParameterSetName="ByInstanceName")]
            [ValidateNotNullorEmpty()] [String] $EnvironmentId,
            [switch]$Download
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
        operationType = "createSupportBundle"
        arguments = @{}
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
        # Create the support bundle and wait for the task to complete
        $CreateSupportBundleTask = ((Invoke-WebRequest @RequestParameters).Content | ConvertFrom-Json)
        if(!(Watch-VCDSTaskCompleted -Task $CreateSupportBundleTask -Timeout 1800)){
            throw "An error occured creating the support bundle $($CreateSupportBundleTask) please check the console and try the operation again."
        } else {
            # Get the support bundle task
            $SupportBundleTask = Get-VCDSTasks -Id $CreateSupportBundleTask.id -IncludeFiles
            # Check if the files should be downloaded
            if($Download){
                # Now download each of the support bundle files locally
                foreach($supportBundleFile in $SupportBundleTask.files){
                    $DownloadURI =  "$ServiceURI/environment/$($Environment.id)/tasks/$($SupportBundleTask.id)/files/$($supportBundleFile.id)/download"
                    $OutputFileName = "$($pwd.Path)\$($supportBundleFile.name)"
                    [Hashtable] $DownloadRequestParameters = @{
                        URI = $DownloadURI
                        Method = "Get"
                        ContentType = "application/json"
                        Headers = @{
                            "Authorization" = "Bearer $($global:VCDService.AccessToken)"
                            "Accept" = "application/json"
                            "Accept-Encoding" = "gzip, deflate, br"
                        }
                        UseBasicParsing = $true
                        OutFile = $OutputFileName
                    }
                    # Make the API Call to create the file
                    (Invoke-WebRequest @DownloadRequestParameters) | Out-Null
                }
            }
            return $SupportBundleTask
        }
    } catch {
        throw "An exception has occured attempting to make the API call to create the support bundle. $_"
    }
}