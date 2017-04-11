#region Private Functions

function Export-ModuleHelper
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        #SourcePath
        [Parameter(Mandatory=$true,ParameterSetName='NoRemoting_Default')]
        [System.IO.DirectoryInfo]$SourcePath,

		#DestinationPath
        [Parameter(Mandatory=$true,ParameterSetName='NoRemoting_Default')]
        [System.IO.DirectoryInfo]$DestinationPath,

		#VerbosePrefix
		[Parameter(Mandatory=$false,ParameterSetName='NoRemoting_Default')]
		[string]$VerbosePrefix,

		#ModuleVersion
		[Parameter(Mandatory=$false,ParameterSetName='NoRemoting_Default')]
		[string]$ModuleVersion
    )

    Process
    {
		$ObjectName = $SourcePath.BaseName
		if ($PSBoundParameters.ContainsKey('ModuleVersion'))
		{
			$ObjectDestinationFolderTemp = Join-Path -Path $DestinationPath.FullName -ChildPath $ObjectName -ErrorAction Stop
			$ObjectDestinationFolder = Join-Path -Path $ObjectDestinationFolderTemp -ChildPath $ModuleVersion -ErrorAction Stop
		}
		else
		{
			$ObjectDestinationFolder = Join-Path -Path $DestinationPath.FullName -ChildPath $ObjectName -ErrorAction Stop
		}

		#Verify DestinationModulePath
		try
		{
			Write-Verbose "$VerbosePrefix. Verify DestinationModulePath"
			if (Test-Path -Path $ObjectDestinationFolder)
			{
				Remove-Item -Path $ObjectDestinationFolder -ErrorAction Stop -Force -Confirm:$false -Recurse
			}
			$null = New-Item -Path $ObjectDestinationFolder -ItemType Directory -ErrorAction Stop
			
			#Copy module folder to destination location
			Write-Verbose "$VerbosePrefix. Copying files"
			Copy-Item -Path "$($SourcePath.FullName)\*" -Destination $ObjectDestinationFolder -Recurse
		}
		catch
		{
			Write-Error "$VerbosePrefix. Verify DestinationModulePath failed. Details: $_" -ErrorAction 'Stop'
		}

		Write-Verbose "$VerbosePrefix. Cleanup"
		#Clean Module Folder
		if (Test-Path -Path "$ObjectDestinationFolder\obj")
		{
			Remove-Item -Path "$ObjectDestinationFolder\obj" -Force -Recurse -Confirm:$false
		}
		if (Test-Path -Path "$ObjectDestinationFolder\bin")
		{
			Remove-Item -Path "$ObjectDestinationFolder\bin" -Force -Recurse -Confirm:$false
		}
		if (Test-Path -Path "$ObjectDestinationFolder\*.pssproj")
		{
			Remove-Item -Path "$ObjectDestinationFolder\*.pssproj" -Force -Recurse -Confirm:$false
		}
		if (Test-Path -Path "$ObjectDestinationFolder\*.vspscc")
		{
			Remove-Item -Path "$ObjectDestinationFolder\*.vspscc" -Force -Recurse -Confirm:$false
		}
		if (Test-Path -Path "$ObjectDestinationFolder\*.pssproj.user")
		{
			Remove-Item -Path "$ObjectDestinationFolder\*.pssproj.user" -Force -Recurse -Confirm:$false
		}
		if (Test-Path -Path "$ObjectDestinationFolder\*.tests.ps1")
		{
			Remove-Item -Path "$ObjectDestinationFolder\*.tests.ps1" -Force -Recurse -Confirm:$false
		}
		if (Test-Path -Path "$ObjectDestinationFolder\Tests")
		{
			Remove-Item -Path "$ObjectDestinationFolder\Tests" -Force -Recurse -Confirm:$false
		}
    }
}

function Build-SolutionModule
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
		#SourcePath
        [Parameter(Mandatory=$true,ParameterSetName='NoRemoting_Default')]
        [System.IO.DirectoryInfo[]]$SourcePath,

		#DestinationPath
        [Parameter(Mandatory=$true,ParameterSetName='NoRemoting_Default')]
        [System.IO.DirectoryInfo]$DestinationPath,

		#ResolveDependancies
		[Parameter(Mandatory=$false,ParameterSetName='NoRemoting_Default')]
		[switch]$ResolveDependancies,

		#CheckCommandReferences
		[Parameter(Mandatory=$false,ParameterSetName='NoRemoting_Default')]
		[switch]$CheckCommandReferences,

		#PSGetRepository
		[Parameter(Mandatory=$false,ParameterSetName='NoRemoting_Default')]
		[hashtable[]]$PSGetRepository
    )
    
    Process
    {
		#Validate All Modules
		try
		{
			if (-not ($AllModuleValidation))
			{
				$AllModuleValidation = @{}
				foreach ($Module in $SourcePath)
				{
					$moduleName = $Module.Name
					$null = $AllModuleValidation.Add($moduleName,(Test-PSModule -ModulePath $Module.FullName -ErrorAction Stop))
				}
			}
		}
		catch
		{
			Write-Error "Unable to validate $moduleName. Details: $_" -ErrorAction 'Stop'
		}

		$CommandsToModuleMapping = @{}

		#Build Module
		foreach ($Module in $SourcePath)
		{
			$moduleName = $Module.Name
			$moduleVersion = $AllModuleValidation[$moduleName].ModuleInfo.Version

			Write-Verbose "Build Module:$moduleName/$moduleVersion started"

            #Check if Module is already built
            try
            {
                $ModuleAlreadyBuild = $false
                $ModuleDependanciesValid = $true
                $ModuleBuildDestinationPath = Join-Path -Path $DestinationPath -ChildPath $moduleName -ErrorAction Stop
                $ModAlreadyBuildTest = Test-PSModule -ModulePath $ModuleBuildDestinationPath -ErrorAction Stop
                if ($AllModuleValidation[$moduleName].IsValid -and $ModAlreadyBuildTest.IsValid -and ($AllModuleValidation[$moduleName].ModuleInfo.Version -eq $AllModuleValidation[$moduleName].ModuleInfo.Version))
				{
                    #Check if Module Dependancies are valid versions
					foreach ($DepModule in $AllModuleValidation[$moduleName].ModuleInfo.RequiredModules)
					{
						$depModuleName=$DepModule.Name
						$depModuleVersion=$DepModule.Version
						$ModuleDependanciesDefinition_NeedsUpdate = $false

						if ($AllModuleValidation.ContainsKey($depModuleName))
						{
							if ($AllModuleValidation[$depModuleName].ModuleInfo.Version -gt $depModuleVersion -or (-not $AllModuleValidation[$depModuleName].IsValid))
							{
								$ModuleDependanciesValid = $false
							}
						}
					}
                    if ($ModuleDependanciesValid)
                    {
                        $ModuleAlreadyBuild = $true
                    }
				}
            }
            catch
            {

            }

			#Build Module if not already built
			if ($ModuleAlreadyBuild)
			{
				Write-Verbose "Build Module:$moduleName/$moduleVersion skipped, already built"
			}
			else
			{
				#Build Module Dependancies
				try
				{
					#Resolve Dependancies
					if ($ResolveDependancies.IsPresent)
					{
						foreach ($ModDependancy in $AllModuleValidation[$moduleName].ModuleInfo.RequiredModules)
						{
							$dependantModuleName = $ModDependancy.Name
							$dependantModuleVersion = $ModDependancy.Version

							Write-Verbose "Build Module:$moduleName/$moduleVersion in progress. Build dependant module:$dependantModuleName/$dependantModuleVersion started"
							$ModDependancyFound = $false
							#Search for module in the Solution
							if (-not $ModDependancyFound)
							{
								if ($AllModuleValidation.ContainsKey($dependantModuleName) -and ($AllModuleValidation[$dependantModuleName].ModuleInfo.Version -ge $dependantModuleVersion))
								{
									Build-SolutionModule -SourcePath $AllModuleValidation[$dependantModuleName].ModuleInfo.ModuleBase -DestinationPath $DestinationPath -ResolveDependancies:$ResolveDependancies -ErrorAction Stop
									$ModDependancyFound = $true

								}
							}

							#Search for module in Solution PSGetRepositories
							if (-not $ModDependancyFound -and ($PSBoundParameters.ContainsKey('PSGetRepository')))
							{
								foreach ($item in $PSGetRepository)
								{
									#Check if Repository is already registered
									$RepoFound = $false
									try
									{
										$Repo = Get-PSRepository -Name $item.Name -ErrorAction Stop
										if ($Repo)
										{
											$RepoFound = $true
										}
									}
									catch
									{

									}
									if (-not $RepoFound)
									{
										$null = Register-PSRepository @item -ErrorAction Stop
									}

									#Search for module
									$PSGet_Params = @{
										Name=$dependantModuleName
										Repository=$item.Name
										MinimumVersion=$dependantModuleVersion
									}
									if ($item.ContainsKey('Credential'))
									{
										$PSGet_Params.Add('Credential',$item.Credential)
									}
									try
									{
										$NugetDependancy = Find-Module @PSGet_Params -ErrorAction Stop
									}
									catch
									{

									}
									if ($NugetDependancy)
									{
										Write-Verbose "Build Module:$moduleName/$moduleVersion in progress. Build dependant module:$dependantModuleName/$dependantModuleVersion in progress. Downloading PSGetPackage: $($NugetDependancy.Name)/$($NugetDependancy.Version)"
										Save-Module @PSGet_Params -Path $DestinationPath -ErrorAction Stop
										$ModDependancyFound = $true
										break
									}
								}
							}

							#Throw Not Found
							if ($ModDependancyFound)
							{
								Write-Verbose "Build Module:$moduleName/$moduleVersion in progress. Build dependant module:$dependantModuleName/$dependantModuleVersion completed"
							}
							else {
								throw "Dependand module: $dependantModuleName/$dependantModuleVersion not found"
							}
						}
					}
				}
				catch
				{
					Write-Error "Build Module:$moduleName/$moduleVersion dependancies failed. Details: $_"
				}

				#Build Module
				try
				{
					#Update Module Dependancies definition
                    if (-not $ModuleDependanciesValid)
                    {
                        Write-Warning "Build Module:$moduleName/$moduleVersion in progress. RequiredModules specification not valid, updating it..."
					    $ModuleDependanciesDefinition = New-Object -TypeName system.collections.arraylist
					    foreach ($DepModule in $AllModuleValidation[$moduleName].ModuleInfo.RequiredModules)
					    {
						    $depModuleName=$DepModule.Name
						    $depModuleVersion=$DepModule.Version
						    $ModuleDependanciesDefinition_NeedsUpdate = $false

						    if ($AllModuleValidation.ContainsKey($depModuleName))
						    {
							    $ModSpec = [Microsoft.PowerShell.Commands.ModuleSpecification]::new(@{
								    ModuleName = $AllModuleValidation[$depModuleName].ModuleInfo.Name
								    ModuleVersion = $AllModuleValidation[$depModuleName].ModuleInfo.Version
							    })
							    $null = $ModuleDependanciesDefinition.Add($ModSpec)
						    }
                            else
                            {
                                $ModSpec = [Microsoft.PowerShell.Commands.ModuleSpecification]::new(@{
								ModuleName = $DepModule.Name
								ModuleVersion = $DepModule.Version
							    })
							    $null = $ModuleDependanciesDefinition.Add($ModSpec)
                            }
					    }
					    if ($ModuleDependanciesDefinition.Count -gt 0)
					    {
						    Update-ModuleManifest -Path $AllModuleValidation[$moduleName].ModuleInfo.Path -RequiredModules $ModuleDependanciesDefinition -ErrorAction Stop
					    }
                    }

					#Check Module Integrity
					if (-not $AllModuleValidation[$moduleName].IsValid)
					{
						Write-Warning "Build Module:$moduleName/$moduleVersion in progress. Not valid, updating version..."
						Update-PSModuleVersion -ModulePath $AllModuleValidation[$moduleName].ModuleInfo.ModuleBase -ErrorAction Stop
						
						#Refresh ModuleValidation
						$AllModuleValidation[$moduleName] = Test-PSModule -ModulePath $AllModuleValidation[$moduleName].ModuleInfo.ModuleBase -ErrorAction Stop
					}
					elseif (-not $AllModuleValidation[$moduleName].IsReadyForPackaging)
					{
						throw "Not ready for packaging. Missing either Author or Description."
					}
					else
					{
						Write-Verbose "Build Module:$moduleName/$moduleVersion in progress. Valid"
					}

					#Check Module Dependancies
					if ($CheckCommandReferences.IsPresent)
					{
						$ModFresh = Import-Module -FullyQualifiedName $AllModuleValidation[$moduleName].ModuleInfo.ModuleBase -Force -PassThru -ErrorAction Stop
						$ModuleSb = [scriptblock]::Create($ModFresh.Definition)
						$AllCommands = Get-AstStatement -Ast $ModuleSb.Ast -Type CommandAst | foreach {$_.GetCommandName()} | Group-Object -NoElement | Select-Object -ExpandProperty Name
						$LocalCommands = Get-AstStatement -Ast $ModuleSb.Ast -Type FunctionDefinitionAst | select -ExpandProperty Name
						$missingDependancies = New-Object -TypeName system.collections.arraylist
						foreach ($cmd in $AllCommands)
						{
							#If command is not in CommandsToModuleMapping
							if (-not $CommandsToModuleMapping.ContainsKey($cmd))
							{
								$CommandFound = $false
								#Check if command is local
								if ($localCommands -contains $cmd)
								{
									$CommandsToModuleMapping.Add($cmd,$moduleName)
									$CommandFound = $true
								}

								#Check if command is in other module in the same solution
								if (-not $CommandFound)
								{
									foreach ($requiredModule in $AllModuleValidation[$moduleName].ModuleInfo.RequiredModules.Name)
									{
										#Check if command is in other module in the same solution
										if ($AllModuleValidation.ContainsKey($requiredModule))
										{
											if ($AllModuleValidation[$requiredModule].ModuleInfo.ExportedCommands.Keys -contains $cmd)
											{
												$CommandsToModuleMapping.Add($cmd,$requiredModule)
												$CommandFound = $true
												break
											}
										}
										#Check if command is in module resolved from NuGet
										else
										{
											try
											{
												$ModPath = Join-Path -Path $DestinationPath -ChildPath $requiredModule -ErrorAction Stop
												$mod = Get-Module -FullyQualifiedName $ModPath -ListAvailable -Refresh -ErrorAction SilentlyContinue
												if ($mod.ExportedCommands.Keys -contains $cmd)
												{
													$CommandsToModuleMapping.Add($cmd,$mod.Name)
													$CommandFound = $true
													break
												}
											}
											catch
											{

											}
										}
									}
								}

								#Command not found
								if (-not $CommandFound)
								{
									$null = $missingDependancies.Add("Unknown\$cmd")
								}
							}
							else
							{
								if ($AllModuleValidation[$moduleName].ModuleInfo.RequiredModules.Name -notcontains $CommandsToModuleMapping[$cmd])
								{
									$null = $missingDependancies.Add("$CommandsToModuleMapping[$cmd])\$cmd")
								}
							}
						}

						if ($missingDependancies.Count -gt 0)
						{
							throw "Missing RequiredModule reference [Module\Command]: $($missingDependancies -join ', ')"
						}
					}

					#Copy Module to DestinationPath
					Export-ModuleHelper -SourcePath $AllModuleValidation[$moduleName].ModuleInfo.ModuleBase -ModuleVersion $AllModuleValidation[$moduleName].ModuleInfo.Version -DestinationPath $DestinationPath -VerbosePrefix "Build Module:$moduleName/$moduleVersion in progress"
				}
				catch
				{
					Write-Error "Build Module:$moduleName/$moduleVersion failed. Details: $_" -ErrorAction 'Stop'
				}

			}

			Write-Verbose "Build Module:$moduleName/$moduleVersion completed"
		}
    }
}

function Publish-SolutionModules
{
    [CmdletBinding()]
    param
    (
        #ModulesFolder
        [Parameter(Mandatory=$true,ParameterSetName='NoRemoting_Default')]
        [System.IO.DirectoryInfo[]]$ModulePath,

		#PSGetRepository
		[Parameter(Mandatory=$false,ParameterSetName='NoRemoting_Default')]
		[hashtable]$PSGetRepository
    )
    
    Process
    {
		#Check if Repository is already registered
		try
		{
			Write-Verbose "Check if Repository is already registered started"
			
			try
			{
				$Repo = Get-PSRepository -Name $PSGetRepository.Name -ErrorAction Stop
			}
			catch
			{

			}
				
			if ((-not $Repo) -or ($Repo.PublishLocation -ne $PSGetRepository.PublishLocation))
			{
				Write-Verbose "Check if Repository is already registered in progress. Repository: $($PSGetRepository.Name) not registered, registering it..."
				$RegisterPSRepository_Params = @{} + $PSGetRepository
				$null = $RegisterPSRepository_Params.Remove('NuGetApiKey')
				$null = Register-PSRepository @PSGetRepository -ErrorAction Stop
			}

			Write-Verbose "Check if Repository is already registered in progress. Updatating Nuget profile config file"

			#Detect Nuget.exe path
			$m = import-Module -Name PowerShellGet -PassThru -Verbose:$false
			$m.Invoke({function init_var {[cmdletbinding()] param () Install-NuGetClientBinaries -BootstrapNuGetExe -CallerPSCmdlet $PSCmdlet}; init_var})
			$NugetExePath = $m.Invoke({$NuGetExePath})

			$StartProcess_params = @{
				FilePath=$NugetExePath
				PassThru=$true
				Wait=$true
			}
			$NugetUserConfigFilePath = "$env:APPDATA\NuGet\NuGet.Config"
			if ($PSGetRepository.ContainsKey('Credential'))
			{
				$UserName = $PSGetRepository['Credential'].UserName
				$UserPassword = $PSGetRepository['Credential'].GetNetworkCredential().Password
				$StartProcess_params.Add('ArgumentList',"sources update -name $($PSGetRepository['Name']) -source $($PSGetRepository['PublishLocation']) -user $UserName -pass $UserPassword -configfile $NugetUserConfigFilePath")
			}
			else
			{
				$StartProcess_params.Add('ArgumentList',"sources remove -name $($PSGetRepository['Name']) -configfile $NugetUserConfigFilePath")
			}
			$Result = Start-Process @StartProcess_params -ErrorAction Stop
			if ($Result.ExitCode -ne 0)
			{
				throw "failed with exitcode: $($Result.ExitCode)"
			}

			Write-Verbose "Check if Repository is already registered completed"
		}
		catch
		{
			Write-Error "Check if Repository is already registered failed. Details: $_" -ErrorAction 'Stop'
		}

		#Publish Module
		foreach ($Module in $ModulePath)
		{
			try
			{
				$moduleName = $Module.Name
				Write-Verbose "Publish Module:$moduleName started"

				#Check if Module is already built
				$ModInfo = Test-PSModule -ModulePath $Module -ErrorAction Stop
				if (-not $ModInfo.IsVersionValid)
				{
					throw 'not builded'
				}

				#Publish Module
				$PublishModuleAndDependacies_Params = @{
					ModuleInfo=$ModInfo.ModuleInfo
                    Repository=$PSGetRepository.Name
                    PublishDependantModules=$true
                    Force=$true
				}
                if ($PSGetRepository.ContainsKey('Credential'))
                {
                    $PublishModuleAndDependacies_Params.Add('Credential',$PSGetRepository.Credential)
                }
                if ($PSGetRepository.ContainsKey('NuGetApiKey'))
                {
                    $PublishModuleAndDependacies_Params.Add('NuGetApiKey',$PSGetRepository.NuGetApiKey)
                }
				Publish-PSModule @PublishModuleAndDependacies_Params  -ErrorAction Stop

				Write-Verbose "Publish Module:$moduleName completed"
			}
			catch
			{
				Write-Error "Publish Module:$moduleName failed. Details: $_" -ErrorAction Stop
			}
		}
    }
}

#endregion

#region Public Functions

function Build-Solution
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        #SolutionConfigPath
        [Parameter(Mandatory=$true,ParameterSetName='NoRemoting_Default')]
        [System.IO.DirectoryInfo]$SolutionConfigPath
    )

    Process
    {
		#Initialize SolutionConfiguration
		try
		{
			Write-Verbose "Initialize SolutionConfiguration started"
			
			$SolutionConfig = Get-SolutionConfiguration -Path $SolutionConfigPath.FullName -ErrorAction Stop

			Write-Verbose "Initialize SolutionConfiguration completed"
		}
		catch
		{
			Write-Error "Initialize SolutionConfiguration failed. Details: $_" -ErrorAction 'Stop'
		}

		#Add/Remove Modules Folder to PSUserPath
		try
		{
			Write-Verbose "Add/Remove Modules Folder to PSUserPath started"
			
			if ($SolutionConfig.Build.AutoloadbuiltModulesForUser)
			{
				foreach ($ModulePath in $SolutionConfig.SolutionStructure.ModulesPath)
				{
					Add-PSModulePathEntry -Path $ModulePath.BuildPath -Scope User -ErrorAction Stop -Force
				}
			}
			else
			{
                try
                {
				    Remove-PSModulePath -Path $SolutionConfig.Build.ModulesBuildPath -Scope User -ErrorAction Stop -WarningAction SilentlyContinue
			    }
                catch
                {

                }
            }
      
			Write-Verbose "Add/Remove Modules Folder to PSUserPath completed"
		}
		catch
		{
			Write-Error "Add/Remove Modules Folder to PSUserPath failed. Details: $_" -ErrorAction 'Stop'
		}

		#Build Solution Modules
		try
		{
			Write-Verbose "Build Solution Modules started"

			foreach ($ModulePath in $SolutionConfig.SolutionStructure.ModulesPath)
			{
				$Modules = Get-ChildItem -Path $ModulePath.SourcePath -Directory -ErrorAction Stop
				Build-SolutionModule -SourcePath $Modules -DestinationPath $ModulePath.BuildPath -ResolveDependancies:$SolutionConfig.Build.AutoResolveDependantModules -PSGetRepository $SolutionConfig.Packaging.PSGetSearchRepositories -CheckCommandReferences:$SolutionConfig.Build.CheckCommandReferences -ErrorAction Stop 
			}
      
			Write-Verbose "Build Solution Modules completed"
		}
		catch
		{
			Write-Error "Build Solution Modules failed. Details: $_" -ErrorAction 'Stop'
		}

		#Run PostBuild Actions
		try
		{
			Write-Verbose "Run PostBuild Actions started"
			
			Foreach ($Action in $SolutionConfig.BuildActions.PostBuild)
			{
				try
				{
					Write-Verbose "Run PostBuild Actions in progress. Action: $($Action['Name']) starting."
					$Null = Invoke-Command -ScriptBlock $Action['ScriptBlock'] -ErrorAction Stop -NoNewScope
					Write-Verbose "Run PostBuild Actions in progress. Action: $($Action['Name']) completed."
				}
				catch
				{
					Write-Warning "Run PostBuild Actions in progress. Action: $($Action['Name']) failed."
					throw $_
				}
			}
      
			Write-Verbose "Run PostBuild Actions completed"
		}
		catch
		{
			Write-Error "Run PostBuild Actions failed. Details: $_" -ErrorAction 'Stop'
		}
	}
}

function Publish-Solution
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        #SolutionConfigPath
        [Parameter(Mandatory=$true,ParameterSetName='NoRemoting_Default')]
        [System.IO.DirectoryInfo]$SolutionConfigPath
    )

    Process
    {
		#Initialize SolutionConfiguration
		try
		{
			Write-Verbose "Initialize SolutionConfiguration started"
			
			$SolutionConfig = Get-SolutionConfiguration -Path $SolutionConfigPath.FullName -ErrorAction Stop

			Write-Verbose "Initialize SolutionConfiguration completed"
		}
		catch
		{
			Write-Error "Initialize SolutionConfiguration failed. Details: $_" -ErrorAction 'Stop'
		}

		#Publish Solution Modules
		try
		{
			Write-Verbose "Publish Solution Modules started"

			#Get All Modules
			$Modules = New-Object -TypeName system.collections.arraylist
			foreach ($modPath in $SolutionConfig.SolutionStructure.ModulesPath)
			{
				Get-ChildItem -Path $modPath.SourcePath -Directory -ErrorAction Stop | foreach {
					$ModuleToPathMapping = @{
						Module=$_
						SourcePath=Join-Path -Path $modPath.SourcePath -ChildPath $_.Name
						BuildPath=Join-Path -Path $modPath.BuildPath -ChildPath $_.Name
					}
					$null = $Modules.Add($ModuleToPathMapping)
				}
			}

			#Determine which modules should be published
			if ((-not $SolutionConfig.Packaging.PublishAllModules) -and ($SolutionConfig.Packaging.PublishSpecificModules.Count -gt 0))
			{
				$Modules = $Modules | Where-Object {$SolutionConfig.Packaging.PublishSpecificModules -contains $_.Module.Name}
			}
			elseif ($SolutionConfig.Packaging.PublishAllModules -and ($SolutionConfig.Packaging.PublishSpecificModules.Count -gt 0))
			{
				Write-Warning "Publish Solution Modules in progress. No Modules are configured to be published"
			}
			if ($SolutionConfig.Packaging.PublishExcludeModules.Count -gt 0)
			{
				$Modules = $Modules | Where-Object {$SolutionConfig.Packaging.PublishExcludeModules -ne $_.Module.Name}
			}

			#Determine if there are PSGetRepositories specified for publishing
			if ($Modules)
			{
				if ($SolutionConfig.Packaging.PSGetPublishRepositories.Count -eq 0)
				{
					Write-Warning "Publish Solution Modules in progress. There are modules for publishing, but no PSGetPublishRepositories are specified"
				}
			}
			else
			{
				Write-Warning "Publish Solution Modules in progress. No Modules for publishing"
			}

			#Publish Modules to each PSGetPublishRepositories
			foreach ($Repo in $SolutionConfig.Packaging.PSGetPublishRepositories)
			{
				Publish-SolutionModules -ModulePath $Modules.BuildPath -PSGetRepository $Repo -ErrorAction Stop 
			}

			Write-Verbose "Publish Solution Modules completed"
		}
		catch
		{
			Write-Error "Publish Solution Modules failed. Details: $_" -ErrorAction 'Stop'
		}
    }
}

function New-SolutionConfiguration
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        #Path
        [Parameter(Mandatory=$true,ParameterSetName='NoRemoting_Default')]
        [System.IO.DirectoryInfo]$Path,

		#Force
        [Parameter(Mandatory=$false,ParameterSetName='NoRemoting_Default')]
        [switch]$Force
    )

    Process
    {
		$SolutionDefinitionFilePath = Join-Path -Path $Path.FullName -ChildPath solutionconfig.psd1 -ErrorAction Stop
		$ConfigExist = Test-Path $SolutionDefinitionFilePath
		if (-not $ConfigExist -or $Force.IsPresent)
		{
			$SolutionConfigurationAsString = @'
$UserVariables = @{
}

$SolutionStructure=@{
	#Example: @(@{SourcePath='c:\modules'},@{BuildPath='c:\modules bin'})
	ModulesPath=@()
}
$Build=@{
	AutoloadbuiltModulesForUser=$true
	AutoResolveDependantModules=$true
	CheckCommandReferences=$false
}
$Packaging=@{
	#Example: @{Name='';SourceLocation='';PublishLocation='';Credential=''}
	PSGetSearchRepositories=@()
	PSGetPublishRepositories=@()
	#List of Modules that should be published to PSGet Repository
	PublishAllModules=$true
	PublishSpecificModules=@()
	PublishExcludeModules=@()
}
$PostBuild=@{
	Scripts=@()
}

'@
			
			Out-File -FilePath $SolutionDefinitionFilePath -InputObject $SolutionConfigurationAsString -Force:$Force.IsPresent -Append:$false -ErrorAction Stop
		}
		else
		{
			Write-Error "File already exist: $($SolutionDefinitionFilePath)" -ErrorAction Stop
		}
	}
}

function Get-SolutionConfiguration
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        #Path
        [Parameter(Mandatory=$true,ParameterSetName='NoRemoting_Default')]
        [System.IO.FileInfo]$Path
    )

    Process
    {
		try
		{
            $SolutionConfigPath = Join-Path -Path $Path.FullName -ChildPath 'solutionconfig.psd1' -ErrorAction Stop
			$SolutionConfigRaw = Get-Content -Path $SolutionConfigPath -Raw -ErrorAction Stop
			New-DynamicConfiguration -Definition ([scriptblock]::Create($SolutionConfigRaw)) -ErrorAction Stop
		}
		catch
		{
			Write-Error "Unable to load SolutionConfiguration: $($Path.FullName). Details: $_"
		}
	}
}

#endregion
