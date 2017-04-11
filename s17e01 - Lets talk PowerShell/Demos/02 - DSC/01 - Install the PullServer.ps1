#Install All necessary DSCResource Modules
Install-Module -Repository PSGallery -Name @(
    'xCertificate'
    'xPSDesiredStateConfiguration'
    'TypeHelper'
    'xSmbShare'
    'xNetworking'
    'xComputerManagement'
    'xSystemSecurity'
    'xCredSSP'
    'cPowerPlan'
    'cUserRightsAssignment'
    'xWebAdministration'
) -Force -AllowClobber

#Request Certificate for the PullServer and export it
$EnvConfig = Import-PowerShellDataFile -Path C:\LabFiles\EnvConfig.psd1
$PullServerComputerName = $EnvConfig.NonNodeData.PullServer.ComputerName
$EnvDomainFqdn = $EnvConfig.NonNodeData.Domain.Fqdn
$EnvDomainNetBiosName = $EnvConfig.NonNodeData.Domain.NetBiosName

$PullServerCert = Get-Certificate -Template 'ContosoWebServer' `
                -DnsName "$PullServerComputerName.$EnvDomainFqdn" `
                -SubjectName "CN = $PullServerComputerName.$EnvDomainFqdn" `
                -CertStoreLocation Cert:\LocalMachine\My
$null = Export-PfxCertificate -Cert $PullServerCert.Certificate `
                        -Force `
                        -FilePath $EnvConfig.NonNodeData.PullServer.Certificate.Location `
                        -ChainOption EndEntityCertOnly `
                        -ProtectTo "$EnvDomainNetBiosName\$PullServerComputerName`$"

#Set the PullServer`s Certificate Thumbprint in the 'Environment Configuration File'.
$EnvConfig.NonNodeData.PullServer.Certificate.Thumbprint = $PullServerCert.Certificate.Thumbprint
$EnvConfigAsString = ConvertTo-String -InputObject $EnvConfig
Out-File -FilePath C:\LabFiles\EnvConfig.psd1 -InputObject $EnvConfigAsString -ErrorAction Stop

#Delete the PullServer`s Certificate from the local machine.
Remove-Item -PSPath $PullServerCert.Certificate.PSPath -Force

#Declare the 'DSC Configuration' for the DSC PullServer.
configuration PullServer
{
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
        try
        {
            $null = [guid]::Parse($_)
            $true
        }
        catch
        {
            throw "$_ should be [guid]"
        }
    })]
        [string]$RegistrationKey
    )
    #Import Required DSC Resources
    Import-DscResource -ModuleName xCertificate
    Import-DscResource -ModuleName xPSDesiredStateConfiguration 
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName xSmbShare

    #Get Required data from the Environment Configuration file
    $EnvDomainFqdn = $ConfigurationData.NonNodeData.Domain.Fqdn
    $PullServerCertThumbprint = $ConfigurationData.NonNodeData.PullServer.Certificate.Thumbprint
    $PullServerCertLocation = $ConfigurationData.NonNodeData.PullServer.Certificate.Location
    $PullServerComputerName = $ConfigurationData.NonNodeData.PullServer.ComputerName

    #Configuration of the Dsc PullServer
    Node $PullServerComputerName
    {
        xPfxImport DscPullServerCert
        {
            Location = 'LocalMachine'
            Thumbprint = $PullServerCertThumbprint
            Path = $PullServerCertLocation
            Store = 'My'
        }

        WindowsFeature DscServiceFeature
        {
            Ensure = 'Present'
            Name =  'Dsc-Service'
        }

        xDSCWebService DscPullServer
        {
            Ensure = 'Present'
            EndpointName = 'PSDSCPullServer'
            Port = 443
            PhysicalPath = "$env:SystemDrive\inetpub\PSDSCPullServer" 
            CertificateThumbPrint = $PullServerCertThumbprint          
            ModulePath = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules" 
            ConfigurationPath = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration"             
            State = 'Started'
            DependsOn = '[WindowsFeature]DscServiceFeature','[xPfxImport]DscPullServerCert'
            UseSecurityBestPractices = $true
        }

        File RegistrationKeyFile
        {
            Ensure          ='Present'
            Type            = 'File'
            DestinationPath = "$env:ProgramFiles\WindowsPowerShell\DscService\RegistrationKeys.txt"
            Contents        = $RegistrationKey
            DependsOn = '[xDSCWebService]DscPullServer'
        }

        File FilesFolder
        {
            Ensure='Present'
            DestinationPath = 'C:\Files'
            Type = 'Directory'
        }
        File DSCNodeCertFolder
        {
            Ensure='Present'
            DestinationPath = 'C:\Files\DscNodeEncryptionCerts'
            Type = 'Directory'
            DependsOn = '[File]FilesFolder'
        }
        xSmbShare FilesFolderShare
        {
            Ensure = 'Present'
            Name = 'Files'
            Path = 'C:\Files'
            DependsOn = '[File]FilesFolder'
        }
    }
}

#Create new 'DSC PullServer RegistrationKey' and save it .txt file.
$RegKey = [guid]::NewGuid().Guid
Out-File -FilePath C:\LabFiles\SensitiveData\PullServerRegKey.txt -InputObject $RegKey

#Compile the PullServer`s Configuration into MOF File, providing the 'Environment Configuration File'.
PullServer -RegistrationKey $RegKey -ConfigurationData C:\LabFiles\EnvConfig.psd1 -OutputPath C:\LabFiles\OutputMof

#Download all required DSC Resources on the PullServer
$EnvConfig = Import-PowerShellDataFile -Path C:\LabFiles\EnvConfig.psd1
$PullServerComputerName = $EnvConfig.NonNodeData.PullServer.ComputerName
$EnvDomainFqdn = $EnvConfig.NonNodeData.Domain.Fqdn
Invoke-Command -ComputerName "$PullServerComputerName.$EnvDomainFqdn" -ScriptBlock {
    Install-Module -Repository PSGallery -Name @(
        'xCertificate'
        'xPSDesiredStateConfiguration'
        'TypeHelper'
        'xSmbShare'
        'xNetworking'
        'xComputerManagement'
        'xSystemSecurity'
        'xCredSSP'
        'cPowerPlan'
        'cUserRightsAssignment'
        'xWebAdministration'
    ) -Force -AllowClobber
}

#Push the 'DSC Configuration MOF' file to the DSC PullServer.
Start-DscConfiguration -Path C:\LabFiles\OutputMof -Wait -Force -Verbose

#Create Password that will be used to protect all of the 'DSC Node Encryption Certificates' while they are transfered.
$DscNodeEncryptionCertPassword = 'P@ssw0rdDscNodeCert'
Out-File -FilePath C:\LabFiles\SensitiveData\DscNodeEncryptionCertPassword.txt -InputObject $DscNodeEncryptionCertPassword

#Configure The Authoring Machine (SRV01) to be able to connect to non-domain joined computers.
$null = Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value * -Force