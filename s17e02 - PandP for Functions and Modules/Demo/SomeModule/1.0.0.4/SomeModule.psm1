#ModuleVersion = 1.0.0.3
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
		[Parameter(Mandatory=$false)]
		[switch]$PassThru = $false
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
        
        $ProcessStartInfo.UseShellExecute = $false
		$ProcessStartInfo.CreateNoWindow = $true
        $Process = [System.Diagnostics.Process]::Start($ProcessStartInfo)
        
		if ($PassThru.IsPresent)
		{
			$Process
		}

        $Process.Dispose()
    }

}
