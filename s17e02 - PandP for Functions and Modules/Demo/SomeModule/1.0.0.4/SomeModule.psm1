#ModuleVersion = 1.0.0.4

<#
   > WHAT'S NEW SINCE 1.0.0.3
	- [New] Support for both Synchronous and Asynchronous execution (using ParameterSets)
	- [Improved] The Wait loop now supports WaitTimeout

#>
function Start-NewProcess
{
    [CmdletBinding(DefaultParameterSetName='Default')]
    param
    (
		# FilePath
		[Parameter(Mandatory=$true)]
        $FilePath,

		# Arguments
		[Parameter(Mandatory=$false)]
        $Arguments,

		# PassThru
		[Parameter(Mandatory=$false, ParameterSetName='Default')]
		[switch]$PassThru = $false,

		# WaitTimeout
		[Parameter(Mandatory=$false, ParameterSetName='Wait')]
		[int]$WaitTimeout = 60,

		# ReturnResult
		[Parameter(Mandatory=$false, ParameterSetName='Wait')]
		[switch]$ReturnResult = $false
    )

    process
    {
		## Initializing the new process StartInfo object
		$ProcessStartInfo = [System.Diagnostics.ProcessStartInfo]::new($FilePath)
		$ProcessStartInfo.RedirectStandardOutput = $true
		$ProcessStartInfo.RedirectStandardError = $true
        $ProcessStartInfo.UseShellExecute = $false
		$ProcessStartInfo.CreateNoWindow = $true
   		if ($PSBoundParameters.ContainsKey('Arguments'))
		{
			$ProcessStartInfo.Arguments = $Arguments
		}
     
		## Start the process
		$Process = [System.Diagnostics.Process]::Start($ProcessStartInfo)

		switch ($PSCmdlet.ParameterSetName)
		{
			'Default' {
				if ($PassThru.IsPresent)
				{
					# Write the Process object in the Output Stream
					$Process
				}
			}

			'Wait' {
				## Start a Timer to monitor the WaitTimeout
				$Timer = [System.Diagnostics.Stopwatch]::StartNew()

				## Wait for the process to complete
				while (-not $WaitCompleted)
				{
					# Check the process state
					if ($Process.HasExited)
					{
						$WaitCompleted = $true
						$Timer.Stop()
					}
					else
					{
						# Check if a Timeout is reached
						if ($Timer.Elapsed.TotalSeconds -gt $WaitTimeout)
						{
							$Timer.Stop()
							throw "Timeout of $WaitTimeout reached."
						}

						Start-Sleep -Milliseconds 250
					}
				}

				## Check exitcode
				if ($Process.exitcode -ne 0)
				{
					# Throw errorcode + errormessage
					$errorMsg = "The process failed with exitcode $($Process.ExitCode)"
					$ProcessOutput_Error = $Process.StandardError.ReadToEnd()
					$ProcessOutput_Standard = $Process.StandardOutput.ReadToEnd()
					if ($ProcessOutput_Error)
					{
						$errorMsg += ". Details: $ProcessOutput_Error"
					}
					elseif ($ProcessOutput_Standard)
					{
						$errorMsg += ". Details: $ProcessOutput_Standard"
					}
					throw $errorMsg
				}
				else
				{
					# Return output
					if ($ReturnResult.IsPresent)
					{
						$Process.StandardOutput.ReadToEnd()
					}
				}
			}

			default
			{
				throw "Unknown ParameterSetName $($PSCmdlet.ParameterSetName)"
			}
		}
        
		## Dispose of the process handle      
		$Process.Dispose()
    }

}
