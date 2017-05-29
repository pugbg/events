#requires -modules @{ModuleName='SoftwareHelper';ModuleVersion='1.0.0.1'}
[CmdletBinding()]
param
(
	[Parameter(Mandatory=$false)]
	[ValidateSet('ChromeInstallation','7ZipInstallation','FileAssociationsConfiguration')]
	[string[]]$Skip
)

process
{
	if ($Skip -notcontains 'ChromeInstallation')
	{
		Install-Chrome -BinPath
	}

	if ($Skip -notcontains '7ZipInstallation')
	{
		Install-7Zip -BinPath
	}
}