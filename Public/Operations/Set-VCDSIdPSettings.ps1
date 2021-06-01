function Set-VCDSIdPSettings(){
    <#
    .SYNOPSIS
    Configure CSP (VMware Cloud Services) as Identity Provider for instance's System Org.

    .DESCRIPTION
    Configure CSP (VMware Cloud Services) as Identity Provider for instance's System Org. Once this has been set users with the VMware Cloud Director Administrator Service role will be able to login to the Cloud Director instance using there myVMware identity.

    PLEASE NOTE: The API Token used in the Connect-VCDService must have "Organization Owner" role in hosting CSP Organization in addition to the "Cloud Director Administrator" service role.

    .PARAMETER InstanceId
    The Cloud Director Instance Id

    .PARAMETER InstanceName
    The Cloud Director Instance Name

    .PARAMETER EnvironmentId
    Optionally The Cloud Director Service Environment Id (Default is used if none is provided)

    .EXAMPLE
    Set-VCDSIdPSettings -InstanceName "PSTest-01"
    Enables or reconfigures CSP (VMware Cloud Services) as Identity Provider for instance's System Org of Cloud Director instance named PSTest-01 in the default environment.

    .NOTES
    AUTHOR: Adrian Begg
    LASTEDIT: 2020-11-17
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
            [ValidateNotNullorEmpty()] [String] $EnvironmentId
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
    $InstanceOperationAPIEndpoint = "$ServiceURI/environment/$($Environment.id)/instances/$($Instance.id)/operations/invokeOperation"
    [Hashtable] $htPayload = @{
        operationType = "SETUP_CSP_AS_IDP_FOR_SYSTEM_ORG"
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
        $SetIdPTask = ((Invoke-WebRequest @RequestParameters).Content | ConvertFrom-Json)
        return $SetIdPTask
    } catch {
        throw "An exception has occurred attempting to make the API call. $_"
    }
}