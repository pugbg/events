#ModuleVersion = 1.0.0.3
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

        $ProcessStartInfo = [System.Diagnostics.ProcessStartInfo]::new($FilePath,$Arguments)
        $ProcessStartInfo.UseShellExecute = $false
		$ProcessStartInfo.RedirectStandardOutput = $true
		$ProcessStartInfo.RedirectStandardError = $true
        $Process = [System.Diagnostics.Process]::Start($ProcessStartInfo)

		#Wait Process to complete
		while (-not $Process.HasExited)
		{
			Start-Sleep -Milliseconds 346
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
			$Process.StandardOutput.ReadToEnd()
		}
        
		$Process.Dispose()
    }

}
