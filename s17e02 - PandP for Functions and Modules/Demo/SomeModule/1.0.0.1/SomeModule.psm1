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
        $r = [System.Diagnostics.Process]::Start($ProcessStartInfo)
        $r.Dispose()
    }

}
