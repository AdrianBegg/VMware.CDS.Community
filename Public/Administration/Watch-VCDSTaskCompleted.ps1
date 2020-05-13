function Watch-VCDSTaskCompleted(){
	<#
	.SYNOPSIS
	 This cmdlet monitors a running task and returns True when the task completes.

	.DESCRIPTION
	 This cmdlet monitors a running task and returns True when the task completes

	.PARAMETER Task
	A PSObject containing a Task object returned by an API POST call

	.PARAMETER Timeout
	Optionally the timeout in seconds before the cmdlet should terminate if the task has not completed.

    Default is 180 seconds.
	For no timeout set to -1

	.EXAMPLE
	Watch-VCDSTaskCompleted -Task $RemoveTask -Timeout 180

	Monitors the task in the object $RemoveTask for a maximum of 60 seconds and returns True when the task completes

	.NOTES
	  NAME: Watch-VCDSTaskCompleted
	  AUTHOR: Adrian Begg
	  LASTEDIT: 2020-02-15
	#>
	Param(
		[Parameter(Mandatory=$True)]
			[ValidateNotNullorEmpty()] [PSObject] $Task,
		[Parameter(Mandatory=$False)]
			[ValidateRange(-1,3600)] [int] $Timeout = 180,
		[Parameter(Mandatory=$False)]
            [ValidateNotNullorEmpty()] [String] $EnvironmentId
	)
	$boolTaskComplete = $false

	# Next check if the EnvironmentId has been provided and is valid
	if($PSBoundParameters.ContainsKey("EnvironmentId")){
		$Environment = $global:VCDService.VCDSEnvironments | Where-Object {$_.id -eq $EnvironmentId}
		if($Environment.count -eq 0){
			throw "An VCDS Environment with the Id $EnvironmentId can not be found. Please check the Id and try again."
		}
	} else {
		$Environment = $global:VCDService.DefaultEnvironment
	}
    Do {
        $objTaskStatus = Get-VCDSTasks -Id $Task.id -EnvironmentId $Environment.Id
        # Generate the percentage based on the steps if set
        if($objTaskStatus.steps.length -gt 0){
            [double] $Percentage = ([int]($objTaskStatus.steps.Split("/")[0]) / [int]($objTaskStatus.steps.Split("/")[1]))* 100
        } else {
            [double] $Percentage = 0
        }
		Write-Debug $objTaskStatus
		# Check if the Percentage is greater then 100 (this can happen) and normalise it
		if($Percentage -gt 100){
			$Percentage = 100
		}
        Write-Progress -Activity "Task Id: $($Task.id)" -PercentComplete ($Percentage)
		if($objTaskStatus.status -ne "IN_PROGRESS"){
            $boolTaskComplete = $true
            if($objTaskStatus.status -ne "SUCCESS"){
                throw "An error occured executing Task Id $($Task.id). Errors: $($objTaskStatus.message)"
                Break
            }
		}
		if($Timeout -ne -1){
			$Timeout--
		}
        Start-Sleep -Seconds 1
    } Until (($Timeout -eq 0) -or $boolTaskComplete)
	if(($Timeout -eq 0) -and !$boolTaskComplete){
		throw "A timeout occured waiting for the Task Id $($Task.id) to complete."
	}
	$boolTaskComplete
}