#ModuleVersion = 1.0.0.2

<#
   > WHAT'S NEW SINCE 1.0.0.1
	- [New]	The function now runs synchronously
	- [New] An exception is thrown if the process exitcode is not zero

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
		$ProcessStartInfo.CreateNoWindow = $true
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
			if ($ProcessOutput_Error)
			{
				$errorMsg += ". Details: $ProcessOutput_Error"
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
