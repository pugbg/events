#ModuleVersion = 1.0.0.6
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
			Write-Error 'Chrome Installation started' -ErrorAction Stop
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
				Start-NewProcess -FilePath "msiexec.exe" -Arguments "/i `"$FilePath`" ALLUSERS=1 /qb! /norestart TRANSFORMS=`"$TransformFilePath`"" -WaitTimeout 3600
				$Result.Status = 'Installed'
			}

			Write-Verbose '7-Zip Installation completed'
		}
		catch
		{
			$Result.Status = 'Failed'
			Write-Error '7-Zip Installation started' -ErrorAction Stop
		}
		finally
		{
			$Result
		}
    }
}

function Get-SoftwareUsage
{
    [CmdletBinding()]
    param
    (
        #Executable
        [Parameter(Mandatory=$false,ParameterSetName='NoRemoting_Default')]
        [string]$Executable,

        #StartTime
        [Parameter(Mandatory=$false,ParameterSetName='NoRemoting_Default')]
        [datetime]$StartTime,

        #ComputerName
        [Parameter(Mandatory=$false,ParameterSetName='NoRemoting_Default')]
        [string]$ComputerName
    )

    Process
    {
		#Retrieve Events
		try
		{
			Write-Verbose "Retrieve Events starting"

			#Prepare FilterScript
			if ($PSBoundParameters.ContainsKey('Executable'))
			{
				$FilterScript = {$_.Properties[5].Value -ilike $Executable} 
			}
			else
			{
				$FilterScript = {$true}
			}

			$GetWinEvent_Params = @{
				FilterHashtable=@{Logname='Security';Id=4688}
			}
			if ($PSBoundParameters.ContainsKey('ComputerName'))
			{
				$GetWinEvent_Params.Add('ComputerName',$ComputerName)
			}
			if ($PSBoundParameters.ContainsKey('StartTime'))
			{
				$GetWinEvent_Params['FilterHashtable'].Add('StartTime',$StartTime)
			}
			Get-WinEvent @GetWinEvent_Params | Where-Object -FilterScript $FilterScript | ForEach-Object {

				[pscustomobject]@{
					Executable = $_.Properties[5].Value
					TimeStamp = $_.TimeCreated
					User=$_.Properties[1].Value
				}

			}
      
			Write-Verbose "Retrieve Events completed"
		}
		catch
		{
			Write-Error "Retrieve Events failed. Details: $_" -ErrorAction 'Stop'
		}
    }
}

#endregion

#region Classes

class SoftwareEntity
{
	[string]$Name
	[Datetime]$TimeStamp
	[string]$Status
}

#endregion