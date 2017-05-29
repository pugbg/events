#ModuleVersion = 1.0.0.2
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

			$Result = [pscustomobject]@{
				Name='Chrome'
				TimeStamp=(Get-Date)
				Status='Unknown'
			}

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

			$Result = [pscustomobject]@{
				Name='Chrome'
				TimeStamp=(Get-Date)
				Status='Unknown'
			}

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

#endregion