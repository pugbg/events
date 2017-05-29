#ModuleVersion = 1.0.0.1
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
        $BinPath
    )

    process
    {
		try
		{
			Write-Verbose 'Chrome Installation starting'

			$ChromeInstalled = Get-Software -Name '*Chrome*'
			if ($ChromeInstalled)
			{
				Write-Verbose 'Chrome Installation skipped, already installed'
			}
			else
			{
				Start-NewProcess -FilePath '' -ReturnResult -ErrorAction Stop
			}

			Write-Verbose 'Chrome Installation completed'
		}
		catch
		{
			Write-Error 'Chrome Installation started' -ErrorAction Stop
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

			$ChromeInstalled = Get-Software -Name '*7zip*'
			if ($ChromeInstalled)
			{
				Write-Verbose '7Zip Installation skipped, already installed'
			}
			else
			{
				Start-NewProcess -FilePath '' -ReturnResult -ErrorAction Stop
			}

			Write-Verbose '7Zip Installation completed'
		}
		catch
		{
			Write-Error 'NotePadPP Installation started' -ErrorAction Stop
		}
    }
}

#endregion