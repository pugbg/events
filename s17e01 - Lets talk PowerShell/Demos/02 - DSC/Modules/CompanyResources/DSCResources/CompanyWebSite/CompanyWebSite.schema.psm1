Configuration CompanyWebSite
{

    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$SiteName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [int]$Port,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$SitePath,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$ContentZipLocation
    )

    Import-DscResource -ModuleName xWebAdministration

    File Site-Folder
    {
        Type = 'Directory'
        DestinationPath = $SitePath
        Ensure = 'Present'
        Force = $true
    }

    File Site-Zip
    {
        DestinationPath = "$SitePath\sitecontent.zip"
        SourcePath = $ContentZipLocation
        Ensure = 'Present'
        Type = 'File'
        Force =  $true
    }

    if ($PSBoundParameters.ContainsKey('ContentZipLocation'))
    {
        Archive Site-Content
        {
            Destination = $SitePath
            Ensure = 'Present'
            Path = "$SitePath\sitecontent.zip"
            DependsOn = '[File]Site-Folder','[File]Site-Zip'
        }
    }

    xWebAppPool WebSite-Pool
    {
        Name = "$SiteName-pool"
        Ensure = 'Present'
    }

    xWebsite WebSite
    {
        Name = $SiteName
        Ensure = 'Present'
        State = 'Started'
        ApplicationPool = "$SiteName-pool"
        BindingInfo = MSFT_xWebBindingInformation
                        {
                            Protocol = 'http'
                            IPAddress = '*'
                            Port = $Port

                        }
        DependsOn = '[xWebAppPool]WebSite-Pool'
        PhysicalPath = $SitePath
    }


}