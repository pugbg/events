function Add-PSModulePathEntry
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        #Path
        [Parameter(Mandatory=$true,ParameterSetName='NoRemoting_Default')]
        [string[]]$Path,

		[Parameter(Mandatory=$false,ParameterSetName='NoRemoting_Default')]
        [switch]$Force = $false,

		[Parameter(Mandatory=$false,ParameterSetName='NoRemoting_Default')]
		[ValidateSet('User','Machine')]
		[string]$Scope = 'Machine'
    )
    
    Begin
    {
          
    }

    Process
    {
		$CurPSModulePathArr = New-Object -TypeName System.Collections.ArrayList
		$CurPSModulePathArr.AddRange((Get-PSModulePath))
		foreach ($Item in $Path)
		{
			if ($CurPSModulePathArr -notcontains $Item)
			{
				if ((Test-Path $Item) -or ($Force.IsPresent))
				{
					$null = $CurPSModulePathArr.Add($Item)
				}
				else
				{
					Write-Error -Message "Path: $Item does not exits" -ErrorAction Stop
				}
			}
		}

		[System.Environment]::SetEnvironmentVariable('PsModulePath',($CurPsModulePathArr -join ';'),[System.EnvironmentVariableTarget]::$Scope)
		[System.Environment]::SetEnvironmentVariable('PsModulePath',($CurPsModulePathArr -join ';'),[System.EnvironmentVariableTarget]::Process)
    }

    End
    {

    }
}

function Set-PSModulePath
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        #parameter1
        [Parameter(Mandatory=$true,ParameterSetName='NoRemoting_Default')]
        [string[]]$Path,

		[Parameter(Mandatory=$false,ParameterSetName='NoRemoting_Default')]
        [switch]$Force = $false,

		[Parameter(Mandatory=$false,ParameterSetName='NoRemoting_Default')]
		[ValidateSet('User','Machine')]
		[string]$Scope = 'Machine'
    )
    
    Begin
    {
          
    }

    Process
    {
		$CurPsModulePathArr = New-Object System.Collections.ArrayList
		foreach ($Item in $Path)
		{
			if ((Test-Path $Item) -or ($Force.IsPresent))
			{
				$CurPsModulePathArr += $Item
			}
			else
			{
				Write-Error -Message "Path: $Item does not exits" -ErrorAction Stop
			}

		}

		[System.Environment]::SetEnvironmentVariable('PsModulePath',($CurPsModulePathArr -join ';'),[System.EnvironmentVariableTarget]::$Scope)
		[System.Environment]::SetEnvironmentVariable('PsModulePath',($CurPsModulePathArr -join ';'),[System.EnvironmentVariableTarget]::Process)
    }

    End
    {

    }
}

function Get-PSModulePath
{
    [CmdletBinding()]
    [OutputType([string[]])]
    param
    (

    )
    
    Begin
    {
          
    }

    Process
    {
		[System.Environment]::GetEnvironmentVariable('PsModulePath',[System.EnvironmentVariableTarget]::Machine) -split ';'
    }

    End
    {

    }
}

function Remove-PSModulePath
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        #Path
        [Parameter(Mandatory=$true,ParameterSetName='NoRemoting_Default')]
        [string[]]$Path,

		[Parameter(Mandatory=$false,ParameterSetName='NoRemoting_Default')]
		[ValidateSet('User','Machine')]
		[string]$Scope = 'Machine'
    )
    
    Begin
    {
          
    }

    Process
    {
		$CurPsModulePathArr = New-Object -TypeName System.Collections.ArrayList
		$CurPsModulePathArr.AddRange((Get-PSModulePath))
		foreach ($Item in $Path)
		{
			if ($CurPsModulePathArr -contains $Item)
			{
				$CurPsModulePathArr.Remove($Item)
			}
			else
			{
				Write-Warning "PSModulePath does not contains: $Item"
			}
		}

		[System.Environment]::SetEnvironmentVariable('PsModulePath',($CurPsModulePathArr -join ';'),[System.EnvironmentVariableTarget]::$Scope)
		[System.Environment]::SetEnvironmentVariable('PsModulePath',($CurPsModulePathArr -join ';'),[System.EnvironmentVariableTarget]::Process)
    }

    End
    {

    }
}

function Test-PSModule
{
    [CmdletBinding()]
	[OutputType([PSModuleValidation])]
    param
    (
        #ModulePath
        [Parameter(Mandatory=$true,ParameterSetName='NoRemoting_Default')]
        [System.IO.DirectoryInfo[]]$ModulePath
    )
    
    Begin
    {
          
    }

    Process
    {
		foreach ($Item in $ModulePath)
		{
			$ModuleValidation = [PSModuleValidation]::new()

			#Validate Module
			try
			{
				Write-Verbose "Validate Module started"
				$ModuleInfo = Get-Module -ListAvailable -FullyQualifiedName $Item.FullName -Refresh -ErrorAction Stop
				if ($ModuleInfo)
				{
					$ModuleValidation.IsModule=$true
					$ModuleValidation.ModuleInfo = $ModuleInfo
				}
      
				Write-Verbose "Validate Module completed"
			}
			catch
			{
				Write-Error "Validate Module failed. Details: $_" -ErrorAction 'Stop'
			}


			#Validate Version Integrity
			if ($ModuleValidation.IsModule)
			{
                #Check Version Control
                try
                {
					$ModulePsd = Import-PSDataFile -FilePath $ModuleValidation.ModuleInfo.Path -ErrorAction Stop
                    $VersionControl = $ModulePsd.PrivateData.VersionControl | ConvertFrom-Json -ErrorAction Stop
                }
                catch
                {

                }

				if ($VersionControl)
				{
                    $ModuleValidation.SupportVersonControl = $true
					$GetFileHash_Params = @{
						Path=(Join-Path -Path $ModuleValidation.ModuleInfo.ModuleBase -ChildPath $ModuleValidation.ModuleInfo.RootModule -ErrorAction Stop)
					}
					if ($VersionControl.HashAlgorithm)
					{
						$GetFileHash_Params.Add('Algorithm',$VersionControl.HashAlgorithm)
					}
					$CurrentHash = Get-FileHash @GetFileHash_Params -ErrorAction Stop

					if ($VersionControl.Version -eq $ModuleValidation.ModuleInfo.Version)
					{
						if ($VersionControl.Hash -eq $CurrentHash.Hash)
						{
							$ModuleValidation.IsVersionValid=$true
						}
                        else
                        {
                            $ModuleValidation.IsNewVersion = $true
                        }
					}
				}
			}

            #Validate IsReadyForPackaging
            if ($ModuleValidation.IsModule)
            {
                if ($ModuleValidation.ModuleInfo.Author -and $ModuleValidation.ModuleInfo.Description)
                {
                    $ModuleValidation.IsReadyForPackaging = $true
                }
            }

			$ModuleValidation
		}
    }

    End
    {

    }
}

function Publish-PSModule
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        #ModuleInfo
        [Parameter(Mandatory=$true,ParameterSetName='NoRemoting_Default')]
        [PSModuleInfo]$ModuleInfo,

        #Credential
        [Parameter(Mandatory=$false,ParameterSetName='NoRemoting_Default')]
        [PScredential]$Credential,

        #Repository
        [Parameter(Mandatory=$false,ParameterSetName='NoRemoting_Default')]
        [string]$Repository,

		#NuGetApiKey
        [Parameter(Mandatory=$false,ParameterSetName='NoRemoting_Default')]
        [string]$NuGetApiKey,

		#Force
        [Parameter(Mandatory=$false,ParameterSetName='NoRemoting_Default')]
        [switch]$Force,

		#PublishDependantModules
        [Parameter(Mandatory=$false,ParameterSetName='NoRemoting_Default')]
        [switch]$PublishDependantModules = $true
    )
    
    Begin
    {
          
    }

    Process
    {
		#Resolve ModuleRootFolder
		try
		{
			Write-Verbose "Resolve ModuleRootFolder started"
			
			$ModuleLeafFolder = Split-Path -Path $ModuleInfo.ModuleBase -Leaf
			$ModuleVersion = New-Object System.Version
			if ([System.Version]::TryParse($ModuleLeafFolder, [ref]$ModuleVersion))
			{
				$ModuleVersionFolder = Split-Path -Path $ModuleInfo.ModuleBase -Parent
				$ModuleRootFolder = Split-Path -Path $ModuleVersionFolder -Parent
			}
			else
			{
				$ModuleRootFolder = Split-Path -Path $ModuleInfo.ModuleBase -Parent
			}

      
			Write-Verbose "Resolve ModuleRootFolder completed"
		}
		catch
		{
			Write-Error "Resolve ModuleRootFolder failed. Details: $_" -ErrorAction 'Stop'
		}
		
		#Publish RequiredModules
		foreach ($ReqModule in $ModuleInfo.RequiredModules)
		{
			$ReqModuleFound = $false
			#Check if Required Module is present in the same folder as the current module
			try
			{
				$ReqModuleInfo = Get-Module -ListAvailable -FullyQualifiedName "$ModuleRootFolder\$($ReqModule.Name)" -Refresh -ErrorAction Stop
				if ($ReqModuleInfo)
				{
					$ReqModuleFound = $true
				}
			}
			catch
			{

			}

			if ($ReqModuleFound)
			{
				$PublishModuleAndDependacies_Params = @{

				} + $PSBoundParameters
				$PublishModuleAndDependacies_Params['ModuleInfo'] = $ReqModuleInfo
				Publish-PSModule @PublishModuleAndDependacies_Params
			}
			else
			{
				throw "Unable to find Required Module: $($ReqModule.Name)"
			}
		}

		#Publish Module
		try
		{
			Write-Verbose "Publish Module started"
			$PublishModule_CommonParams = @{
				Repository=$Repository
			}

			if ($PSBoundParameters.ContainsKey('Credential'))
			{
				$PublishModule_CommonParams.Add('Credential',$Credential)
			}

			#Check if module already exist on the Repository
			try
			{
				$ModExist = Find-Module @PublishModule_CommonParams -Name $ModuleInfo.Name -MinimumVersion $ModuleInfo.Version -ErrorAction Stop
			}
			catch
			{

			}
			
			if ($ModExist)
			{
				Write-Verbose "Publish Module in progress. Module already exist on the PSGetRepo"
			}
			else
			{
				$PublishModule_Params = @{
					Path=$ModuleInfo.ModuleBase
				} + $PublishModule_CommonParams
				if ($PSBoundParameters.ContainsKey('NuGetApiKey'))
				{
					$PublishModule_Params.Add('NuGetApiKey',$NuGetApiKey)
				}
				Publish-Module @PublishModule_Params -Force -ErrorAction Stop
			}

			Write-Verbose "Publish Module completed"
		}
		catch
		{
			Write-Error "Publish Module failed. Details: $_" -ErrorAction 'Stop'
		}
    }

    End
    {

    }
}

function Update-PSModuleVersion
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        #ModulePath
        [Parameter(Mandatory=$true,ParameterSetName='NoRemoting_Default')]
        [System.IO.DirectoryInfo[]]$ModulePath
    )
    
    Begin
    {
          
    }

    Process
    {
		$ModuleValidation = Test-PSModule -ModulePath $ModulePath -ErrorAction Stop
		if ($ModuleValidation.IsModule)
		{
			$ModuleInfo = $ModuleValidation.ModuleInfo
			$CurrentVersion = [System.Version]::Parse($ModuleInfo.Version)
			$NewVersion = [System.Version]::new($CurrentVersion.Major,$CurrentVersion.Minor,$CurrentVersion.Build,($CurrentVersion.Revision + 1))
			$NewHash = Get-FileHash -Path (Join-Path -Path $ModuleValidation.ModuleInfo.ModuleBase -ChildPath $ModuleValidation.ModuleInfo.RootModule -ErrorAction Stop) -ErrorAction Stop
            $VersionControlAsJson = ConvertTo-Json -InputObject ([pscustomobject]@{
				Hash=$NewHash.Hash
				HashAlgorithm=$NewHash.Algorithm
				Version=$NewVersion.ToString()
            }) -ErrorAction Stop -Compress
            Update-ModuleManifest -Path $ModuleValidation.ModuleInfo.Path -ModuleVersion $NewVersion -PrivateData @{
                    VersionControl=$VersionControlAsJson
			    } -ErrorAction Stop -ErrorVariable er
		}
    }

    End
    {

    }
}

#region Public Classes

class PSModuleValidation {

    [psmoduleinfo]$ModuleInfo
    [bool]$IsModule=$false
    [bool]$IsVersionValid=$false
    [bool]$IsNewVersion=$false
    [bool]$SupportVersonControl=$false
    [bool]$IsReadyForPackaging=$false
    hidden [bool]$_test = (Add-Member -InputObject $this -MemberType ScriptProperty -Name IsValid -Value {
		if ($this.IsModule -and $this.IsVersionValid -and $this.SupportVersonControl)
		{
			$true
		}
		else
		{
			$false
		}
	} -SecondValue {})

}

#endregion