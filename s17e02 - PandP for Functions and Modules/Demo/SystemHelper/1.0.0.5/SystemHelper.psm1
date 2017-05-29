#ModuleVersion = 1.0.0.5

<#
   > WHAT'S NEW SINCE 1.0.0.4
	- [Changed] Module renamed to SystemHelper
	- [Improved] Advanced Parameter validation
	- [Improved] Correct OutputType function decoration
	- [New] Added generic error handling with support for the ErrorAction common parameter
	- [New] Added Verbose messages to track status/progress

#>

function Start-NewProcess
{
    [CmdletBinding(DefaultParameterSetName='Default')]
	[OutputType([System.Diagnostics.Process], ParameterSetName="Default")]
	[OutputType([string], ParameterSetName="Wait")]
    param
    (
		#FilePath
		[Parameter(Mandatory=$true)]
		[ValidateScript({
			if (Test-Path -Path $_)
			{
				$true
			}
			else
			{
				throw "File: $_ not found"
			}
		})]
        $FilePath,

		#Arguments
		[Parameter(Mandatory=$false)]
        $Arguments,

		#PassThru
		[Parameter(Mandatory=$false,ParameterSetName='Default')]
		[switch]$PassThru = $false,

		#WaitTimeout
		[Parameter(Mandatory=$false,ParameterSetName='Wait')]
		[ValidateRange(1,3600)]
		[int]$WaitTimeout = 60,

		#ReturnResult
		[Parameter(Mandatory=$false,ParameterSetName='Wait')]
		[switch]$ReturnResult = $false
    )

    Process
    {
		try
		{
			### Start the process
			try
			{
				## Initializing the new process StartInfo object
				Write-Verbose -Message "Initializing the new process StartInfo preferences"

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

				Write-Verbose -Message "The Process was started successfully"
			}
			catch
			{
				# Rethrow with custom message
				throw "The process failed to start. Details: $_" 
			}

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
					Write-Verbose -Message "Waiting for the process to complete (max $WaitTimeout seconds)"
					$WaitCompleted = $false
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

					Write-Verbose -Message "The process completed successfully"


					## Check exitcode
					if ($Process.exitcode -ne 0)
					{
						# Throw errorcode + errormessage
						try
						{
							Write-Verbose -Message "Reading data from Output and Error streams"

							$errorMsg = "The process failed with exitcode $($Process.ExitCode)."
							$ProcessOutput_Error = $Process.StandardError.ReadToEnd()
							$ProcessOutput_Standard = $Process.StandardOutput.ReadToEnd()
							if ($ProcessOutput_Error)
							{
								$errorMsg += " Details: $ProcessOutput_Error"
							}
							elseif ($ProcessOutput_Standard)
							{
								$errorMsg += "Details: $ProcessOutput_Standard"
							}
						}
						catch
						{
							$errorMsg += " Failed to read data from Output and Error streams. Details: $_"
						}
						finally
						{
							throw $errorMsg
						}
					}
					elseif ($ReturnResult.IsPresent)
					{
						# Return output
						$Process.StandardOutput.ReadToEnd()
					}
				}

				default
				{
					throw "Unknown ParameterSetName $($PSCmdlet.ParameterSetName)"
				}
			}
		}
		catch
		{
			Write-Error -Exception $_ -Message "$_" -Category NotSpecified -ErrorId 0 -TargetObject $MyInvocation.MyCommand.Name
		}
		finally
		{
			# Dispose
			if($Process)
			{
				$Process.Dispose()
			}
		}
    }
}
