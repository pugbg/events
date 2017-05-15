function Start-NewProcess
{

    [CmdletBinding()]
    param
    (
		#FilePath
		[Parameter(Mandatory=$true)]
        $FilePath,

		#Arguments
		[Parameter(Mandatory=$false)]
        $Arguments,

		#PassThru
		[Parameter(Mandatory=$false,ParameterSetName='Local_Default')]
		[switch]$PassThru = $false,

		#Wait
		[Parameter(Mandatory=$false,ParameterSetName='Local_Wait')]
		[switch]$Wait = $false,

		#WaitTimeout
		[Parameter(Mandatory=$false,ParameterSetName='Local_Wait')]
		[int]$WaitTimeout = 60,

		#ReturnResult
		[Parameter(Mandatory=$false,ParameterSetName='Local_Wait')]
		[switch]$ReturnResult = $false
    )

    process
    {
		if ($PSBoundParameters.ContainsKey('Arguments'))
		{
			$ProcessStartInfo = [System.Diagnostics.ProcessStartInfo]::new($FilePath,$Arguments)
		}
		else
		{
			$ProcessStartInfo = [System.Diagnostics.ProcessStartInfo]::new($FilePath)
		}
        
		if ($ReturnResult.IsPresent)
		{
			$ProcessStartInfo.RedirectStandardOutput = $true
		}

		$ProcessStartInfo.RedirectStandardError = $true
        $ProcessStartInfo.UseShellExecute = $false
		$ProcessStartInfo.CreateNoWindow = $true
        $Process = [System.Diagnostics.Process]::Start($ProcessStartInfo)
        
		switch ($PSCmdlet.ParameterSetName)
		{
			{$_ -ilike '*Default'} {
				if ($PassThru.IsPresent)
				{
					$Process
				}
			}

			{$_ -ilike '*Wait'} {

				#Wait the process to exit
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

				if ($Process.ExitCode -ne 0)
				{
					$errorMsg = "Failed with exitcode $($Process.ExitCode)"
					if ($Process.StandardError)
					{
						$errorMsg+=". Details: $($Process.StandardError.ReadToEnd())"
					}
					throw $errorMsg
				}
				elseif ($Process.ExitCode -eq 0 -and $ReturnResult.IsPresent)
				{
					$Process.StandardOutput.ReadToEnd()
				}

				break
			}
			defailt
			{
				throw "Unknown ParameterSetName $($PSCmdlet.ParameterSetName)"
			}
		}




        $Process.Dispose()
    }

}
