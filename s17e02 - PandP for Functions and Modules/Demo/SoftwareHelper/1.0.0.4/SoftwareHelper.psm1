#ModuleVersion = 1.0.0.4
#region Private Functions

function Get-Software
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        #Name
        [Parameter(Mandatory=$true,ParameterSetName='NoRemoting_Default')]
        [string]$Name
    )
    
    Begin
    {
          
    }

    Process
    {
    
    }

    End
    {

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

			$GetWinEvent_Params = @{
				FilterHashtable=@{Logname='System';Id=4688}
			}
			if ($PSBoundParameters.ContainsKey('ComputerName'))
			{
				$GetWinEvent_Params.Add('ComputerName',$ComputerName)
			}
			$AllEvents = Get-WinEvent @GetWinEvent_Params -ErrorAction Stop			
      
			Write-Verbose "Retrieve Events completed"
		}
		catch
		{
			Write-Error "Retrieve Events failed. Details: $_" -ErrorAction 'Stop'
		}

		#Filter Events
		if ($PSBoundParameters.ContainsKey('Executable'))
		{
			try
			{
				Write-Verbose "Filter Events starting"
					
				$AllEvents = $AllEvents | Where-Object -FilterScript {$_.Properties[5].Value -ilike $Executable}
      
				Write-Verbose "Filter Events completed"
			}
			catch
			{
				Write-Error "Filter Events failed. Details: $_" -ErrorAction 'Stop'
			}
		}

		#Return Result
		$Result = New-Object -TypeName system.collections.Arraylist
		foreach ($item in $AllEvents)
		{
			$ItemResult = [pscustomobject]@{
				TimeStamp=$item.TimeCreated
				Software=$item.Properties[5].Value
				User=$item.Properties[1].Value
			}
			$null = $Result.Add()
		}
		$Result
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