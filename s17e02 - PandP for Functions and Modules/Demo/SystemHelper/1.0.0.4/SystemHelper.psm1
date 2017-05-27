#ModuleVersion = 1.0.0.4
function Start-NewProcess
{
    [CmdletBinding()]
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

		#Wait
		[Parameter(Mandatory=$true,ParameterSetName='Wait')]
		[switch]$Wait = $false,

		#WaitTimeout
		[Parameter(Mandatory=$false,ParameterSetName='Wait')]
		[ValidateRange(1,3600)]
		[int]$WaitTimeout = 60,

		#ReturnResult
		[Parameter(Mandatory=$false,ParameterSetName='Wait')]
		[switch]$ReturnResult = $false
    )

    process
    {
		#Start New Process
		try
		{
			Write-Verbose "Start New Process started"

			#Create the ProcessStartInfo
			$ProcessStartInfo = [System.Diagnostics.ProcessStartInfo]::new($FilePath)
			if ($PSBoundParameters.ContainsKey('Arguments'))
			{
				$ProcessStartInfo.Arguments = $Arguments
			}
			if ($ReturnResult.IsPresent)
			{
				$ProcessStartInfo.RedirectStandardOutput = $true
			}
			$ProcessStartInfo.RedirectStandardError = $true
			$ProcessStartInfo.UseShellExecute = $false
			$ProcessStartInfo.CreateNoWindow = $true
        
			#Start the process
			$Process = [System.Diagnostics.Process]::Start($ProcessStartInfo)

			Write-Verbose "Start New Process completed"
		}
		catch
		{
			Write-Error "Start New Process Failed. Details: $_"
		}

		switch ($PSCmdlet.ParameterSetName)
		{
			'Default' {
				if ($PassThru.IsPresent)
				{
					$Process
				}
			}

			'Wait' {

				#Wait the Process
				try
				{
					Write-Verbose "Wait the Process started"

					$Timer = [System.Diagnostics.Stopwatch]::StartNew()
					while (-not $WaitCompleted)
					{
						#Check Process State
						if ($Process.HasExited)
						{
							$WaitCompleted = $true
							$Timer.Stop()
						}
						else
						{
							#Check if Timeout is reached
							if ($Timer.Elapsed.TotalSeconds -gt $WaitTimeout)
							{
								$Timer.Stop()
								throw "Timeout of $WaitTimeout reached."
							}

							Start-Sleep -Seconds 2
						}
					}

					Write-Verbose "Wait the Process completed"
				}
				catch
				{
					Write-Error "Wait the Process failed. Details: $_"
				}

				if ($Process.exitcode -ne 0)
				{
					#Parse Error
					try
					{
						Write-Verbose "Parse Error started"
						$ProcessOutput_Error = $Process.StandardError.ReadToEnd()
						$ProcessOutput_Standard = $Process.StandardOutput.ReadToEnd()
						if ($ProcessOutput_Error)
						{
							$errorMsg = ". Details: $ProcessOutput_Error"
						}
						elseif ($ProcessOutput_Standard)
						{
							$errorMsg = ". Details: $ProcessOutput_Standard"
						}
						Write-Verbose "Parse Error completed"
					}
					catch
					{
						Write-Error "Parse Error failed. Details: $_"
					}

					#Return errorcode + errormessage
					$errorMsg = "Failed with exitcode $($Process.ExitCode)" + $errorMsg
					Write-Error -Message $errorMsg -ErrorAction Stop
				}
				elseif ($ReturnResult.IsPresent)
				{
					$Process.StandardOutput.ReadToEnd()
				}
			}

			default
			{
				throw "Unknown ParameterSetName $($PSCmdlet.ParameterSetName)"
			}
		}
        
		#Dispose
		$Process.Dispose()
    }
}
