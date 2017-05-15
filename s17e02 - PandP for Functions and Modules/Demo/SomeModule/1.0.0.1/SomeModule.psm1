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
        $ProcessStartInfo.RedirectStandardOutput = $true
        $ProcessStartInfo.RedirectStandardError = $true
        $ProcessStartInfo.UseShellExecute = $false
        $r = [System.Diagnostics.Process]::Start($ProcessStartInfo)
        $r.WaitForExit()
        $r.StandardOutput.ReadToEnd()
        $r.Dispose()
    }

}
