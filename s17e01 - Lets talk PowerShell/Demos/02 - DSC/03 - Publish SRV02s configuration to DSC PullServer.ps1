#Use the Composite Resources to to update the configuration for SRV02
Configuration CompanyServers_Config
{
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [pscredential]$DomainJoinCredential
    )
    
    Import-DscResource -ModuleName CompanyResources

    $DomainFqdn = $ConfigurationData.NonNodeData.Domain.Fqdn
    $DnsServerIpAddress = $ConfigurationData.NonNodeData.Domain.DnsServersIpAddress

    Node $AllNodes.NodeName
    {
        CompanyServer ServerSettings
        {
            ServerName = $Node.NodeName
            DomainFqdn = $DomainFqdn
            DomainCredential = $DomainJoinCredential
            DnsServerIpAddress = $DnsServerIpAddress
        }

        if ($Node.Role.Name -eq 'WebServer')
        {
            CompanyWebServer WebServerSettings
            {
                RemoveDefaultWebSiteAndPool = $true
            }

            CompanyWebSite fourthcoffeeWebSite
            {
                SiteName = $Node.Role.Settings.SiteName
                Port = $Node.Role.Settings.Port
                SitePath = $Node.Role.Settings.SitePath
                ContentZipLocation = $Node.Role.Settings.ContentZipLocation
                DependsOn = '[CompanyServer]ServerSettings'
            }
        }
    }
}

#Compile the 'DSC Configurations' for SRV02 into MOF files.
Get-ChildItem -Path C:\LabFiles\OutputMof | Remove-Item -Force
$ServersMOFs = CompanyServers_Config -ConfigurationData C:\LabFiles\EnvConfig.psd1 -OutputPath C:\LabFiles\OutputMof

#Publish required 'DSC Rsources' to the 'DSC PullServer'
$EnvConfig = Import-PowerShellDataFile -Path C:\LabFiles\EnvConfig.psd1
$PullServerComputerName = $EnvConfig.NonNodeData.PullServer.ComputerName
$PullServerSes = New-PSSession -ComputerName $PullServerComputerName
Invoke-Command -Session $PullServerSes -ScriptBlock {
    Get-Module | Remove-Module -Force
    Publish-DSCModuleAndMof -Source 'C:\Program Files\WindowsPowerShell\Modules' -Verbose:$false
}

#Publish the 'DSC Nodes' Configuration MOF files to the 'DSC PullServer' thru PowerShell Remoting.
$NodeConfigurationLocation = $EnvConfig.NonNodeData.PullServer.NodeConfigurationLocation
$ServersMOFs | foreach {
    Copy-Item -ToSession $PullServerSes -Path $_.FullName -Destination $NodeConfigurationLocation -Force
}

#Create Checksums of the 'DSC Node' Configuration MOF Files on the 'DSC PullServer'.
Invoke-Command -Session $PullServerSes -ScriptBlock {
    Get-ChildItem -Path $Using:NodeConfigurationLocation | foreach {
        New-DscChecksum -Path $_.FullName -OutPath $Using:NodeConfigurationLocation -Force
    }
}