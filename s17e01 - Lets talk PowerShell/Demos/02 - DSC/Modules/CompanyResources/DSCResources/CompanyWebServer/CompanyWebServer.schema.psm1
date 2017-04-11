Configuration CompanyWebServer
{

    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [bool]$RemoveDefaultWebSiteAndPool
    )

    Import-DscResource -ModuleName xWebAdministration

    WindowsFeature IIS-Feature
    {
        Name = 'Web-Server'
        Ensure = 'Present'
    }

    WindowsFeature IIS-AspNet45
    {
        Name = 'Web-Asp-Net45'
        Ensure = 'Present'
    }

    WindowsFeature IIS-Tools
    {
        Name = 'Web-Mgmt-Tools'
        Ensure = 'Present'
    }
    

    if ($RemoveDefaultWebSiteAndPool)
    {
        xWebAppPool DefaultAppPool
        {
            Name = 'DefaultAppPool'
            Ensure = 'Present'
            State = 'Stopped'
            autoStart = $false
            DependsOn = '[WindowsFeature]IIS-Feature'
        }

        xWebsite DefaultWebSite
        {
            Name = 'Default Web Site'
            Ensure = 'Absent'
            DependsOn = '[xWebAppPool]DefaultAppPool'
        }
    }

}