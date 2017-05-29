#ModuleVersion = 1.0.0.5
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
		[Parameter(Mandatory=$true)]
        $BinPath,

		[Parameter(Mandatory=$true)]
        $PassThru
    )

    process
    {
		try
		{
			Write-Verbose 'Chrome Installation starting'

			$Result = [SoftwareEntity]::new()

			$ChromeInstalled = Get-Software -Name '*Chrome*'
			if ($ChromeInstalled)
			{
				$Result.Status = 'AlreadyInstalled'
				Write-Verbose 'Chrome Installation skipped, already installed'
			}
			else
			{
				Start-NewProcess -FilePath '' -ReturnResult -ErrorAction Stop
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
		[Parameter(Mandatory=$true)]
        $BinPath
    )

    process
    {
		try
		{
			Write-Verbose '7Zip Installation starting'

			$Result = [SoftwareEntity]::new()

			$ChromeInstalled = Get-Software -Name '*notepad*'
			if ($ChromeInstalled)
			{
				$Result.Status = 'AlreadyInstalled'
				Write-Verbose '7Zip Installation skipped, already installed'
			}
			else
			{
				Start-NewProcess -FilePath '' -ReturnResult -ErrorAction Stop
				$Result.Status = 'Installed'
			}

			Write-Verbose '7Zip Installation completed'
		}
		catch
		{
			$Result.Status = 'Failed'
			Write-Error 'NotePadPP Installation started' -ErrorAction Stop
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
				FilterHashtable=@{Logname='System';Id=4688}
			}
			if ($PSBoundParameters.ContainsKey('ComputerName'))
			{
				$GetWinEvent_Params.Add('ComputerName',$ComputerName)
			}
			$AllEvents = Get-WinEvent @GetWinEvent_Params -ErrorAction Stop	| Where-Object -FilterScript $FilterScript | foreach {
				[pscustomobject]@{
					TimeStamp=$_.TimeCreated
					Software=$_.Properties[5].Value
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