function Set-VCDSProviderAdminPassword(){
    <#
    .SYNOPSIS
    Reset the Provider Administrator account password for a Cloud Director service instance.

    .DESCRIPTION
    Reset the Provider Administrator account password for a Cloud Director service instance.

    .PARAMETER InstanceId
    The Cloud Director Instance Id

    .PARAMETER InstanceName
    The Cloud Director Instance Name

    .PARAMETER NewProviderAdminPassword
    The Password to set as the Provider Administrator account password for the provided Cloud Director instance

    .PARAMETER EnvironmentId
    Optionally The Cloud Director Service Environment Id (Default is used if none is provided)

    .EXAMPLE
    Set-VCDSProviderAdminPassword -InstanceName "CloudDirector-TestInstance-01" -NewProviderAdminPassword "SuperSt0rngP@ssword!"
    Resets the administrator user password for the instance named "CloudDirector-TestInstance-01" in the CDS default environment to "SuperSt0rngP@ssword!"

    .NOTES
    AUTHOR: Adrian Begg
    LASTEDIT: 2020-08-31
	VERSION: 1.0
    #>
    [CmdletBinding(DefaultParameterSetName="ByInstanceId")]
    Param(
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceId")]
            [ValidateNotNullorEmpty()]  [string] $InstanceId,
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceName")]
            [ValidateNotNullorEmpty()]  [string] $InstanceName,
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceId")]
        [Parameter(Mandatory=$True, ParameterSetName="ByInstanceName")]
            [ValidateNotNullorEmpty()]  [string] $NewProviderAdminPassword,
        [Parameter(Mandatory=$False)]
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

    if($PSCmdlet.ParameterSetName -eq "ByInstanceName"){
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
        operationType = "RESET_PROVIDER_ADMIN_PASSWORD"
        arguments = @{}
    }

    # Set the arguments to reset the password
    [Hashtable] $htArguments = @{
        providerAdminNewPassword = $NewProviderAdminPassword
        providerAdminNewPasswordConfirm = $NewProviderAdminPassword
    }
    # Set the arguments to the Payload
    $htPayload.arguments = $htArguments

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
        $SetInstancePassword = ((Invoke-WebRequest @RequestParameters).Content | ConvertFrom-Json)
        return $SetInstancePassword
    } catch {
        throw "An exception has occurred attempting to make the API call. $_"
    }
}