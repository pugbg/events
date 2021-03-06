@{
	AllNodes = @(
	@{
		NodeName = 'sof-srv02'
		CertificateFile = '\\sof-srv01\Files\DscNodeEncryptionCerts\sof-srv02.cer'
		Role = @{
			Settings = @{
				SiteName = 'fourthcoffee'
				Port = '80'
				SitePath = 'c:\websites\fourthcoffee'
				ContentZipLocation = '\\sof-dc01\Files\fourthcoffee.zip'
			}
			Name = 'WebServer'
		}
	}
	)
	NonNodeData = @{
		Domain = @{
			NetBiosName = 'contoso'
			Fqdn = 'contoso.local'
			DnsServersIpAddress = '10.10.10.1'
		}
		PullServer = @{
			Url = 'https://sof-srv01.contoso.local/PSDSCPullServer.svc'
			ComputerName = 'sof-srv01'
			NodeConfigurationLocation = 'C:\Program Files\WindowsPowerShell\DscService\Configuration'
			Certificate = @{
				Location = '\\sof-dc01\Files\DscPullServerCert.pfx'
				Thumbprint = 'D6CA0C1ED02844594DF80AF4C1D694A84AAE16D3'
			}
		}
		DscNodeSettings = @{
			Certificates = @{
				EncryptionCertLocation = '\\sof-srv01\Files\DscNodeEncryptionCerts'
				EncryptionCertTemplateName = 'ContosoDscNode'
			}
		}
	}
}

