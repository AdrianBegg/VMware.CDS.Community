function New-VCDSInstance(){
    <#
    .SYNOPSIS
    Creates a new instance of Cloud Director Service under the currently connected VMware Console Services Portal account.

    .DESCRIPTION
    Creates a new instance of Cloud Director Service under the currently connected VMware Console Services Portal account.

    If successfully invoked returns the Task Id of the job to create the instance

    .PARAMETER Name
    The Name of the CDS Instance for you to identify your instance

    .PARAMETER EnvironmentId
    The Cloud Director Environment Id to host the instance

    .PARAMETER TemplateId
    The Cloud Director Template Id of the image to deploy.

    .PARAMETER AdministratorPassword
    The password for the administrator user in the System Org

    .EXAMPLE
    New-VCDSInstance -Name "CDS-Instanace-01" -EnvironmentId "urn:vcdc:environment:3fccbd2a-003c-4303-8f1a-8569853236ac" -TemplateId "urn:vcdc:deploymentTemplate:cf4e35ce-65f0-4590-8f6f-79a86d270d06" -AdministratorPassword "Welcome@123"
    Creates a new VCDS Instance in the environment with the Id "urn:vcdc:environment:3fccbd2a-003c-4303-8f1a-8569853236ac" using Template with the Id urn:vcdc:deploymentTemplate:cf4e35ce-65f0-4590-8f6f-79a86d270d06

	.NOTES
    AUTHOR: Adrian Begg
    LASTEDIT: 2020-02-14
	VERSION: 1.0
    #> 
    Param(
        [Parameter(Mandatory=$True)]
            [ValidateNotNullorEmpty()] [String] $Name,
        [Parameter(Mandatory=$True)]
            [ValidateNotNullorEmpty()] [String] $EnvironmentId,
        [Parameter(Mandatory=$True)]
            [ValidateNotNullorEmpty()] [String] $TemplateId,
        [Parameter(Mandatory=$True)]
            [ValidateNotNullorEmpty()] [String] $AdministratorPassword
    )
    if(!$global:VCDService.IsConnected){
        throw "You are not currently connected to the VMware Console Services Portal (CSP) for VMware Cloud Director Service. Please use Connect-VCDService cmdlet to connect to the service and try again."
    }
    # Next check if the EnvironmentId and TemplateId valid
    $Environment = Get-VCDSEnvironments -Id $EnvironmentId
    if($Environment.count -eq 0){
        throw "An VCDS Environment with the Id $EnvironmentId can not be found. Please check the Id and try again."
    }
    $Template =  Get-VCDSTemplates -EnvironmentId $EnvironmentId -Id $TemplateId
    if($Template.count -eq 0){
        throw "An VCDS Template with the Id $TemplateId can not be found in Environment $EnvironmentId. Please check the Id and try again."
    }
    # Check if an instance already exists with the provided Name
    $NamedInstance = Get-VCDSInstance -EnvironmentId $EnvironmentId -Name $Name
    if($NamedInstance.count -ne 0){
        throw "An instance with the Name $Name already exists in the environment with the Id $EnvironmentId please check the Name and try again."
    }

    # Setup a Service URI...need to review this after some further testing
    $ServiceURI = ($global:VCDService.CDSEnvironments | Where-Object{$_.type -eq "PRODUCTION"}).starfleetConfig.operatorURL
    # Setup a HashTable for the API call to the Cloud Gateway
    $TemplateAPIEndpoint = "$ServiceURI/environment/$EnvironmentId/instances"
    [Hashtable] $htPayload = @{
        name = $Name
        domain = ""
        environmentId = $EnvironmentId
        templateId = $TemplateId
        instanceParams = @{}
        password = $AdministratorPassword
    }

    # A Hashtable of Request Parameters
    [Hashtable] $RequestParameters = @{
        URI = $TemplateAPIEndpoint
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
        $CreateInstanceResult = ((Invoke-WebRequest @RequestParameters).Content | ConvertFrom-Json)
        return $CreateInstanceResult
    } catch {
        throw "An exception has occured attempting to make the API call. $_"
    }
}
