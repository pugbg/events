#requires -modules @{ModuleName='SystemHelper';ModuleVersion='1.0.0.4'}
[CmdletBinding()]
param
(
	[Parameter(Mandatory=$false)]
	[ValidateSet('ChromeInstallation','NotepadPPInstallation','FileAssociationsConfiguration')]
	[string[]]$Skip
)

process
{
	if ($Skip -notcontains 'ChromeInstallation')
	{
		try
		{
			Write-Verbose 'ChromeInstallation starting'

			$ChromeInstalled = #check if chrome is installed
			if ($ChromeInstalled)
			{
				Write-Verbose 'ChromeInstallation skipped, already installed'
			}
			else
			{
				Start-NewProcess -FilePath '' -ReturnResult -ErrorAction Stop
			}

			Write-Verbose 'ChromeInstallation completed'
		}
		catch
		{
			Write-Error 'ChromeInstallation started' -ErrorAction Stop
		}
	}

	#Copy it for every step
}