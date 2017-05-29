#ModuleVersion = 1.0.0.4
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
		[Parameter(Mandatory=$false,ParameterSetName='Default')]
		[switch]$PassThru = $false,

		#Wait
		[Parameter(Mandatory=$true,ParameterSetName='Wait')]
		[switch]$Wait = $false,

		#WaitTimeout
		[Parameter(Mandatory=$false,ParameterSetName='Wait')]
		[int]$WaitTimeout = 60,

		#ReturnResult
		[Parameter(Mandatory=$false,ParameterSetName='Wait')]
		[switch]$ReturnResult = $false
    )

    process
    {
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

		switch ($PSCmdlet.ParameterSetName)
		{
			'Default' {
				if ($PassThru.IsPresent)
				{
					$Process
				}
			}

			'Wait' {
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

				#Check exitcode
				if ($Process.exitcode -ne 0)
				{
					#Return errorcode + errormessage
					$errorMsg = "Failed with exitcode $($Process.ExitCode)"
					$ProcessOutput_Error = $Process.StandardError.ReadToEnd()
					$ProcessOutput_Standard = $Process.StandardOutput.ReadToEnd()
					if ($ProcessOutput_Error)
					{
						$errorMsg+=". Details: $ProcessOutput_Error"
					}
					elseif ($ProcessOutput_Standard)
					{
						$errorMsg+=". Details: $ProcessOutput_Standard"
					}
					Write-Error -Message $errorMsg -ErrorAction Stop
				}
				else
				{
					#Return output
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
        
		#Dispose
		$Process.Dispose()
    }

}
