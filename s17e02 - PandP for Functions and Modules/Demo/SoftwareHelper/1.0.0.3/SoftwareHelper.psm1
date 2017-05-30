#ModuleVersion = 1.0.0.3
#region Private Functions

function Get-Software
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        #Name
        [Parameter(Mandatory=$false,ParameterSetName='NoRemoting_Default')]
        [string]$Name
    )
    
    Begin
    {
		$RegSearchPaths = @(
			'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
			'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
		)
    }

    Process
    {
		#Seach for Software
		try
		{
			if ($PSBoundParameters.ContainsKey('Name'))
			{
				$FilterScript = {$_.Displayname -ilike $Name}
			}
			else
			{
				$FilterScript = {$true}
			}
			$RegSearchPaths | foreach { Get-ItemProperty -Path $_ }  | Where-Object -FilterScript $FilterScript | foreach {
				[pscustomobject]@{
					Name=$_.DisplayName
					Version=$_.DisplayVersion
					Publisher=$_.Publisher
					InstallDate=$_.InstallDate
				}
			}
		}
		catch
		{
			Write-Error -Message "Search for Software failed. Details $_."
		}

    }
}

#endregion

#region Public Functions

function Install-Chrome
{

    [CmdletBinding()]
	[OutputType([SoftwareEntity])]
    param
    (
		#FilePath
		[Parameter(Mandatory=$true)]
        [System.IO.FileInfo]$FilePath,

		#PassThru
		[Parameter(Mandatory=$true)]
        [switch]$PassThru
    )

    process
    {
		#Chrome Installation
		try
		{
			Write-Verbose 'Chrome Installation starting'

			$Result = [SoftwareEntity]::new()
			$Result.Name='Chrome'
			$Result.Executable=$FilePath
			$Result.TimeStamp=(Get-Date)
			$Result.Status='Unknown'

			$ChromeInstalled = Get-Software -Name '*Chrome*'
			if ($ChromeInstalled)
			{
				$Result.Status = 'AlreadyInstalled'
				Write-Verbose 'Chrome Installation skipped, already installed'
			}
			else
			{
				Start-NewProcess -FilePath $FilePath.FullName -ReturnResult -ErrorAction Stop
				$Result.Status = 'Installed'
			}

			Write-Verbose 'Chrome Installation completed'
		}
		catch
		{
			$Result.Status = 'Failed'
			Write-Error "Chrome Installation failed. Details: $_"
		}
		finally
		{
			$Result
		}
    }
}

function Install-7Zip
{

    [CmdletBinding()]
	[OutputType([SoftwareEntity])]
    param
    (
		#FilePath
		[Parameter(Mandatory=$true)]
        [System.IO.FileInfo]$FilePath,

		#TransformFilePath
		[Parameter(Mandatory=$true)]
        [System.IO.FileInfo]$TransformFilePath,

		#PassThru
		[Parameter(Mandatory=$true)]
        [switch]$PassThru
    )

    process
    {
		#7-Zip Installation
		try
		{
			Write-Verbose '7-Zip Installation starting'

			$Result = [SoftwareEntity]::new()
			$Result.Name='7-Zip'
			$Result.Executable=$FilePath
			$Result.TimeStamp=(Get-Date)
			$Result.Status='Unknown'

			$7ZipInstalled = Get-Software -Name '*7-zip*'
			if ($7ZipInstalled)
			{
				$Result.Status = 'AlreadyInstalled'
				Write-Verbose '7-Zip Installation skipped, already installed'
			}
			else
			{
				Start-NewProcess -FilePath "C:\Windows\System32\msiexec.exe" -Arguments "/i `"$FilePath`" ALLUSERS=1 /qb! /norestart TRANSFORMS=`"$TransformFilePath`"" -WaitTimeout 3600
				$Result.Status = 'Installed'
			}

			Write-Verbose '7-Zip Installation completed'
		}
		catch
		{
			$Result.Status = 'Failed'
			Write-Error "7-Zip Installation failed. Details: $_"
		}
		finally
		{
			$Result
		}
    }
}

#endregion

#region Classes

class SoftwareEntity
{
	[string]$Name
	[string]$Executable
	[Datetime]$TimeStamp
	[string]$Status
}

#endregion