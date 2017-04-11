function Register-DscNode
{

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [switch]$Workgroup,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$NodeComputerName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$NodeIpAddress,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PullServerRegistrationKey,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PullServerUrl,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$EncryptionCertificateTemplateName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$EncryptionCertificateStoreLocation,

        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [securestring]$EncryptionCertificatePassword,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [pscredential]$NodeCredentials
    )

    begin
    {

    }

    process
    {
        #Request Dsc Encryption Certificate
        try
        {
            Write-Verbose 'Request Dsc Encryption Certificate started'

            $EncryptionCert = Get-Certificate -Template $EncryptionCertificateTemplateName `
                            -DnsName $NodeComputerName `
                            -SubjectName "CN = $NodeComputerName" `
                            -CertStoreLocation Cert:\LocalMachine\My `
                            -ErrorAction Stop
            $EncryptionCertThumbprint = $EncryptionCert.Certificate.Thumbprint

            Write-Verbose 'Request Dsc Encryption Certificate completed'
        }
        catch
        {
            Write-Error -Message "Request Dsc Encryption Certificate failed. Details: $_" -ErrorAction Stop
        }

        #Export the Encryption Certificate to the EncryptionCertificateStoreLocation
        try
        {
            Write-Verbose 'Export the Encryption Certificate to the EncryptionCertificateStoreLocation started'

            $null = Export-Certificate -Cert $EncryptionCert.Certificate `
                                -Type CERT `
                                -FilePath "$EncryptionCertificateStoreLocation\$NodeComputerName.cer" `
                                -Force `
                                -ErrorAction Stop

            Write-Verbose 'Export the Encryption Certificate to the EncryptionCertificateStoreLocation completed'
        }
        catch
        {
            Write-Error "Export the Encryption Certificate to the EncryptionCertificateStoreLocation failed. Details: $_" -ErrorAction Stop
        }

        #Establish PSSesssion to the Node
        try
        {
            Write-Verbose 'Establish PSSesssion to the Node started'
            $NewPsSession_params = @{
                Credential=$NodeCredentials 
                Authentication='Negotiate'
            }
            if ($Workgroup.IsPresent)
            {
                $NewPsSession_params.Add('ComputerName',$NodeIpAddress)
            }
            else
            {
                $NewPsSession_params.Add('ComputerName',$NodeComputerName)
            }

            $PsSession = New-PSSession @NewPsSession_params -ErrorAction Stop

            Write-Verbose 'Establish PSSesssion to the Node completed'
        }
        catch
        {
            Write-Error "Establish PSSesssion to the Node failed. Details: $_" -ErrorAction Stop
        }

        #Transfer the Encryption Certificate to the Node
        try
        {
            Write-Verbose 'Transfer the Encryption Certificate to the Node started'

            $tempCertExport = Export-PfxCertificate -Cert $EncryptionCert.Certificate `
                                    -Force `
                                    -FilePath "$env:TEMP\$NodeComputerName`_temp.pfx" `
                                    -ChainOption EndEntityCertOnly `
                                    -Password $EncryptionCertificatePassword `
                                    -ErrorAction Stop

            Copy-Item -ToSession $PsSession -Path $tempCertExport.FullName -Destination "c:\" -Force -ErrorAction Stop

            Invoke-Command -Session $PsSession -ScriptBlock {

                $null = Import-PfxCertificate -FilePath "c:\$Using:NodeComputerName`_temp.pfx" `
                                        -CertStoreLocation Cert:\LocalMachine\My `
                                        -Password $Using:EncryptionCertificatePassword `
                                        -ErrorAction Stop

                Remove-Item -Path "c:\$Using:NodeComputerName`_temp.pfx" -Force -ErrorAction Stop
            } -ErrorAction Stop

            Remove-Item -Path $tempCertExport.FullName -Force -ErrorAction Stop
            Remove-Item -PSPath $EncryptionCert.Certificate.PsPath -Force -ErrorAction Stop

            Write-Verbose 'Transfer the Encryption Certificate to the Node completed'
        }
        catch
        {
            Write-Error "Transfer the Encryption Certificate to the Node failed. Details: $_" -ErrorAction Stop
        }     
       
        #Complie the Node MetaConfiguration 
        try
        {
            Write-Verbose 'Complie the Node MetaConfiguration started'

            $tempFolderMetaConfig = New-Item c:\tempMetaConfOut -ItemType directory -ErrorAction Stop -Force

            $New_NodeMetaConf_Params = @{
                EncryptionCertificateThumbprint=$EncryptionCertThumbprint
                PullServerRegistrationKey=$PullServerRegistrationKey
                PullServerUrl=$PullServerUrl
                ConfigurationNames=$NodeComputerName
                OutputPath=$tempFolderMetaConfig.FullName
            }
            if ($Workgroup.IsPresent)
            {
                $New_NodeMetaConf_Params.Add('NodeComputerName',$NodeIpAddress)
            }
            else
            {
                $New_NodeMetaConf_Params.Add('NodeComputerName',$NodeComputerName)
            }

            $NodeMetaConfigMOF = New_NodeMetaConf @New_NodeMetaConf_Params -ErrorAction Stop

            Write-Verbose 'Complie the Node MetaConfiguration finished'
        }
        catch
        {
            Write-Error "Complie the Node MetaConfiguration failed. Details: $_"
        }

        #Push the Node MetaConfiguration
        try
        {
            Write-Verbose 'Push the Node MetaConfiguration started'

            $SetDscLocalConfigurationManager_Params = @{
                Path='C:\tempMetaConfOut'
                Credential=$NodeCredentials
                Force=$true
            }
            if ($Workgroup.IsPresent)
            {
                $SetDscLocalConfigurationManager_Params.Add('ComputerName',$NodeIpAddress)
            }
            else
            {
                $SetDscLocalConfigurationManager_Params.Add('ComputerName',$NodeComputerName)
            }

            $null = Set-DscLocalConfigurationManager @SetDscLocalConfigurationManager_Params -ErrorAction Stop

            Remove-Item -Path $tempFolderMetaConfig -Force -Recurse -Confirm:$false -ErrorAction Stop
            
            Write-Verbose 'Push the Node MetaConfiguration finished'
        }
        catch
        {
            Write-Error "Push the Node MetaConfiguration failed. Details: $_"
        }
    }

    end
    {

    }

}

#region Private Functions

[DscLocalConfigurationManager()]
configuration New_NodeMetaConf
{
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$EncryptionCertificateThumbprint,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PullServerRegistrationKey,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PullServerUrl,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$NodeComputerName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$ConfigurationNames
    )

    Node $NodeComputerName
    {
        Settings
        {
            RefreshMode = 'Pull'
            RefreshFrequencyMins = 30
            RebootNodeIfNeeded = $true
            CertificateID = $EncryptionCertificateThumbprint
        }

        ConfigurationRepositoryWeb Contoso-PullServer
        {
            ServerURL = $PullServerUrl
            RegistrationKey = $PullServerRegistrationKey
            ConfigurationNames = $ConfigurationNames
        }

        ResourceRepositoryWeb Contoso-PullServer
        {
            ServerURL = $PullServerUrl
            RegistrationKey = $PullServerRegistrationKey
        }

        ReportServerWeb Contoso-PullServer
        {
            ServerURL = $PullServerUrl
        }
    }
}

#endregion