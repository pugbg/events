#ModuleVersion = 1.0.0.3

<#
   > WHAT'S NEW SINCE 1.0.0.2
	- [Improved] If the stdErr stream is empty, the exception contains the stdOut stream data

#>

function Start-NewProcess
{

    [CmdletBinding()]
    param
    (
        $FilePath,

        $Arguments
    )

    process
    {
		## Initializing the new process StartInfo object
        $ProcessStartInfo = [System.Diagnostics.ProcessStartInfo]::new($FilePath,$Arguments)
        $ProcessStartInfo.UseShellExecute = $false
		$ProcessStartInfo.RedirectStandardOutput = $true
		$ProcessStartInfo.RedirectStandardError = $true

		## Start the process
        $Process = [System.Diagnostics.Process]::Start($ProcessStartInfo)

		## Wait for the process to complete
		while (-not $Process.HasExited)
		{
			Start-Sleep -Milliseconds 250
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
			Write-Error -Message $errorMsg -ErrorAction Stop
		}
		else
		{
			# Return output
			$Process.StandardOutput.ReadToEnd()
		}

		## Dispose of the process handle      
		$Process.Dispose()
    }

}
