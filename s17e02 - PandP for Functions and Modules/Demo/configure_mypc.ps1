#requires -modules @{ModuleName='SoftwareHelper';ModuleVersion='1.0.0.1'}
[CmdletBinding()]
param
(
    #BinariesPath
  	[Parameter(Mandatory=$true)]
	[string]$BinariesPath,

	[Parameter(Mandatory=$false)]
	[ValidateSet('ChromeInstallation','7ZipInstallation')]
	[string[]]$Skip
)

process
{
	if ($Skip -notcontains 'ChromeInstallation')
	{
		Install-Chrome -FilePath "$BinariesPath\ChromeStandaloneSetup64.exe"
	}

	if ($Skip -notcontains '7ZipInstallation')
	{
		Install-7Zip -FilePath "$BinariesPath\7z920-x64.msi" -TransformFilePath "$BinariesPath\assoc.mst"
	}
}