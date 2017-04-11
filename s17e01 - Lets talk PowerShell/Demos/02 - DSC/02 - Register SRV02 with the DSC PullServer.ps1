#Use the Register-DscNode function to register SRV02
$EnvConfig = Import-PowerShellDataFile -Path C:\LabFiles\EnvConfig.psd1
$PullServerRegistrationKey = Get-Content -Path C:\LabFiles\SensitiveData\PullServerRegKey.txt
$EncryptionCertPass = Get-Content -Path C:\LabFiles\SensitiveData\DscNodeEncryptionCertPassword.txt

Register-DscNode -NodeComputerName 'sof-srv02' `
                    -NodeIpAddress '10.10.10.12' `
                    -PullServerUrl $EnvConfig.NonNodeData.PullServer.Url `
                    -PullServerRegistrationKey $PullServerRegistrationKey `
                    -EncryptionCertificateTemplateName $EnvConfig.NonNodeData.DscNodeSettings.Certificates.EncryptionCertTemplateName `
                    -EncryptionCertificateStoreLocation $EnvConfig.NonNodeData.DscNodeSettings.Certificates.EncryptionCertLocation `
                    -EncryptionCertificatePassword (ConvertTo-SecureString -String $EncryptionCertPass -AsPlainText -Force) `
                    -Verbose

#Update the Environment Configuration File
$EnvConfig.AllNodes = @(@{
    NodeName='sof-srv02'
    CertificateFile=Join-Path -Path $EnvConfig.NonNodeData.DscNodeSettings.Certificates.EncryptionCertLocation -ChildPath 'sof-srv02.cer'
    Role=@{
        Name='WebServer'
        Settings=@{
            SiteName='fourthcoffee'
            Port='80'
            ContentZipLocation='\\sof-dc01\Files\fourthcoffee.zip'
            SitePath='c:\websites\fourthcoffee'
        }
    }
})
$EnvConfigAsString = ConvertTo-String -InputObject $EnvConfig
Out-File -FilePath C:\LabFiles\EnvConfig.psd1 -InputObject $EnvConfigAsString -ErrorAction Stop
