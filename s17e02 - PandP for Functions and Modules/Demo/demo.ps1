#region About

#    Patterns and Practices for writing 
#    PowerShell functions and modules

#    Georgi Ivanov and Konstantin Kostov

#endregion

#region Agenda

	# - Day1  -> PS Module basics
	#			 Working with executables
	#
	# - Day2  -> Multiple PS Module versions support
	#			 Basic error validation
	#
	# - Day20 -> ParameterSets
	#            Parameter Handling inside the function
	#			 Async call handling
	#
	# - Day23 -> Parameter Validation
	#            Generic Error handling
	#            Implementing different Output types
	#
	# - Day40 -> Module Interdependency
	#            Private Functions
	#            Error-prone logical operations
	#            PrefferenceVariables propagation
	#
	# - Day42 -> Output formatting
	#            Authoring experience improvements
	#
	# - Day43 -> Output streaming
	#			 Splatting

#endregion

#region A long time ago

	# We need universal helper function for process execution to rule them all. 
	# As the current approaches all have disadvantages

	# - Argument parsing issues
	New-Item -Path C:\TempFolder -ItemType Directory -Force
	ICACLS.EXE C:\TempFolder /GRANT EVERYONE:(F)
	
	# - Output parsing
	Start-Process -FilePath icacls.exe -ArgumentList 'C:\TempFolder /GRANT EVERYONE:(F)'

	# - Error parsing
	ipconfig /alll

#endregion

#region Day 1

    # 14:00 - I need to automate the iisreset
    Import-Module "$ModulesPath\SomeModule" -RequiredVersion 1.0.0.1 -PassThru -Force -OutVariable mod
	psedit (Join-Path -Path $mod.ModuleBase -ChildPath 'SomeModule.psm1')
	psedit (Join-Path -Path $mod.ModuleBase -ChildPath 'SomeModule.psd1')
	$null = Set-PSBreakpoint -Script $mod.Path -Line 16

    Start-NewProcess -FilePath C:\Windows\System32\iisreset.exe
    # Outcome:
    # - Life is good, going for a coffee

    # 17:59 - I want to use the function to ping
	Start-NewProcess -FilePath C:\Windows\System32\ping.exe -Arguments '127.0.0.1'
    Start-NewProcess -FilePath C:\Windows\System32\ipconfig.exe -Arguments '/alll'
    # Outcome:
    # - No exection feedback
    # - No Output
    # - Async execution

#endregion

#region Day 2

    # 9:47 - After a short nap and a morning shower I decided to fix the function
    Import-Module "$ModulesPath\SomeModule" -RequiredVersion 1.0.0.2 -PassThru -Force -OutVariable mod
	psedit (Join-Path -Path $mod.ModuleBase -ChildPath 'SomeModule.psd1')
	psedit (Join-Path -Path $mod.ModuleBase -ChildPath 'SomeModule.psm1')
	$null = Set-PSBreakpoint -Script $mod.Path -Line 24

    Start-NewProcess -FilePath C:\Windows\System32\ipconfig.exe -Arguments '/alll'
	Start-NewProcess -FilePath C:\Windows\System32\ping.exe -Arguments '127.0.0.1'

    # Outcome:
    # - Exception is not displayed if it is not in the ErrorStream
    
	# 15:00 - Fixing the "Exception is not displayed if it is not in the ErrorStream"
	Import-Module "$ModulesPath\SomeModule" -RequiredVersion 1.0.0.3 -PassThru -Force -OutVariable mod
	$null = Set-PSBreakpoint -Script $mod.Path -Line 23
	psedit (Join-Path -Path $mod.ModuleBase -ChildPath 'SomeModule.psm1')

	Start-NewProcess -FilePath C:\Windows\System32\ipconfig.exe -Arguments '/alll'

#endregion

#region Day 20

    # 17:00 - New corporate policy arrived. It uninstalls Chrome and 7zip.
    #         I decided to engineer-around it.

    # 17:59 - After short brainstorming I figured what I need:
    # - Ability to execute proccess both in Foreground and Background
    Import-Module "$ModulesPath\SomeModule" -RequiredVersion 1.0.0.4 -PassThru -Force -OutVariable mod
	psedit (Join-Path -Path $mod.ModuleBase -ChildPath 'SomeModule.psm1')
	$null = Set-PSBreakpoint -Script $mod.Path -Line 38

    Start-NewProcess -FilePath C:\Windows\System32\ping.exe -Arguments '127.0.0.1'
    Start-NewProcess -FilePath C:\Windows\System32\ping.exe -Arguments '127.0.0.1' -PassThru
    Start-NewProcess -FilePath C:\Windows\System32\ping.exe -Arguments '127.0.0.1' -ReturnResult

    Start-NewProcess -FilePath "$BinariesPath\ChromeStandaloneSetup64.exe" -Arguments '/silent /install' -WaitTimeout 3600
    Start-NewProcess -FilePath "msiexec.exe" -Arguments "/i `"$BinariesPath\7z920-x64.msi`" ALLUSERS=1 /qb! /norestart TRANSFORMS=`"$BinariesPath\assoc.mst`"" -WaitTimeout 3600
    # Outcome
    # - Everything works!

#endregion

#region Day 23

    # 10:00 - A colleague saw what I`ve done, and wanted to use my module, so I decided to:
	# - Rename the module so it is easier to understand the purpose of the commands inside it
    # - Implement validation of the input parameters
	# - Implement generic error handling
	# - Add Verbose logging so anyone can see what the code is doing.
    Import-Module "$ModulesPath\SystemHelper" -RequiredVersion 1.0.0.5 -PassThru -Force -OutVariable mod
	psedit (Join-Path -Path $mod.ModuleBase -ChildPath 'SystemHelper.psm1')
	$null = Set-PSBreakpoint -Script $mod.Path -Line 60

    Start-NewProcess -FilePath "$BinariesPath\ChromeStandaloneSetup64.exe" -Arguments '/silent /install' -WaitTimeout 9999
    Start-NewProcess -FilePath "$BinariesPath\ChromeStandaloneSetup65.exe" -Arguments '/silent /install' -WaitTimeout 9999
    Start-NewProcess -FilePath "$BinariesPath\ChromeStandaloneSetup64.exe" -Arguments '/silent /install' -WaitTimeout 360
    Start-NewProcess -FilePath "msiexec.exe" -Arguments "/i $BinariesPath\7z920-x64.msi ALLUSERS=1 /qb! /norestart TRANSFORMS=$BinariesPath\assoc.mst" -WaitTimeout 120 -Verbose

#endregion

#region Day 40

    # 10:00 - A collegue came with the proposal to make a universal script 
	#         that configures the computer as we want it to be. We dicussed it and 
	#         came with the conclusion that:
	# - We should make SoftwareHelper module that is responsible for software detection and installation
	# - Should support being rerun several times
    Import-Module "$ModulesPath\SystemHelper" -RequiredVersion 1.0.0.5 -PassThru -Force
	Import-Module "$ModulesPath\SoftwareHelper" -RequiredVersion 1.0.0.1 -PassThru -Force -OutVariable mod
	$null = Set-PSBreakpoint -Script $mod.Path -Line 71,111
	psedit (Join-Path -Path $mod.ModuleBase -ChildPath 'SystemHelper.psd1')
	psedit "$ModulesPath\configure_mypc.ps1"

    & "$ModulesPath\configure_mypc.ps1" -BinariesPath $BinariesPath -Verbose
    . "$ModulesPath\configure_mypc.ps1" -BinariesPath $BinariesPath -Verbose
	. "$ModulesPath\configure_mypc.ps1" -BinariesPath $BinariesPath -Skip 'ChromeInstallation' -Verbose

#endregion

#region Day 42

    # 10:00 - We want the function to return details about the software installation state
    Import-Module "$ModulesPath\SystemHelper" -RequiredVersion 1.0.0.5 -PassThru -Force
    Import-Module "$ModulesPath\SoftwareHelper" -RequiredVersion 1.0.0.2 -PassThru -Force -OutVariable mod
	$null = Set-PSBreakpoint -Script $mod.Path -Line 75
	psedit (Join-Path -Path $mod.ModuleBase -ChildPath 'SoftwareHelper.psd1')

	Install-Chrome -FilePath "$BinariesPath\ChromeStandaloneSetup64.exe" -PassThru
    Install-Chrome -FilePath "$BinariesPath\ChromeStandaloneSetup64.exe" -PassThru | Where-Object {$_.Status -eq 'Failed'}
	# Outcome
	# - Crappy formatting
	# - Intellisense does not recognise the output

	# 14:00 - Lunch is over. Lets improve the function output
    Import-Module "$ModulesPath\SystemHelper" -RequiredVersion 1.0.0.5 -PassThru -Force
    Import-Module "$ModulesPath\SoftwareHelper" -RequiredVersion 1.0.0.3 -PassThru -Force -OutVariable mod
	$null = Set-PSBreakpoint -Script $mod.Path -Line 76
	psedit (Join-Path -Path $mod.ModuleBase -ChildPath 'SoftwareHelper.psd1')
	psedit (Join-Path -Path $mod.ModuleBase -ChildPath 'types\softwarehelper.format.ps1xml')

	Install-Chrome -FilePath "$BinariesPath\ChromeStandaloneSetup64.exe" -PassThru
	Install-Chrome -FilePath "$BinariesPath\ChromeStandaloneSetup64.exe" -PassThru | Where-Object {$_.Status -eq 'AlreadyInstalled'}
		
#endregion

#region Day 43

	# 10:00 - I want to check who is using Chrome both on my computer and remote computers
    Import-Module "$ModulesPath\SystemHelper" -RequiredVersion 1.0.0.5 -PassThru -Force
	Import-Module "$ModulesPath\SoftwareHelper" -RequiredVersion 1.0.0.4 -PassThru -OutVariable mod -Force
    $null = Set-PSBreakpoint -Script $mod.Path -Line 191
	psedit (Join-Path -Path $mod.ModuleBase -ChildPath 'SoftwareHelper.psd1')

	Get-SoftwareUsage -Executable *Chrome.exe -StartTime (get-date).AddHours(-5) | ft
	Get-SoftwareUsage -Executable *Chrome.exe -StartTime (get-date).AddHours(-5) | select -First 1
	Get-SoftwareUsage -Executable *Chrome.exe -StartTime (get-date).AddHours(-5) | Where-Object {$_.User -eq 'Administrator'}
    Get-SoftwareUsage -Executable *Chrome.exe -StartTime (get-date).AddHours(-5) -ComputerName 'localhost'
	# Outcome
	# - The overall command performance is bad, because it is waiting to collect all date before returning it.

	# 14:00 - I`ve decided to improve the performance
    Import-Module "$ModulesPath\SystemHelper" -RequiredVersion 1.0.0.5 -PassThru -Force
	Import-Module "$ModulesPath\SoftwareHelper" -RequiredVersion 1.0.0.5 -PassThru -OutVariable mod -Force
    $null = Set-PSBreakpoint -Script $mod.Path -Line 191
	psedit (Join-Path -Path $mod.ModuleBase -ChildPath 'SoftwareHelper.psd1')

	Get-SoftwareUsage -Executable *Chrome.exe -StartTime (get-date).AddHours(-5) | ft
	Get-SoftwareUsage -Executable *Chrome.exe -StartTime (get-date).AddHours(-5) | select -First 1
	Get-SoftwareUsage -Executable *Chrome.exe -StartTime (get-date).AddHours(-5) | Where-Object {$_.User -eq 'Administrator'}

	# 17:00 - I`ve decided to improve the performance even more by:
	# - Making the command stream the result as it is retrieved from the provider
    Import-Module "$ModulesPath\SystemHelper" -RequiredVersion 1.0.0.5 -PassThru -Force
	Import-Module "$ModulesPath\SoftwareHelper" -RequiredVersion 1.0.0.6 -PassThru -OutVariable mod -Force
    $null = Set-PSBreakpoint -Script $mod.Path -Line 191
	psedit (Join-Path -Path $mod.ModuleBase -ChildPath 'SoftwareHelper.psd1')

	Get-SoftwareUsage -Executable *Chrome.exe -StartTime (get-date).AddHours(-5)
	Get-SoftwareUsage -Executable *Chrome.exe -StartTime (get-date).AddHours(-5) | select -First 1
	Get-SoftwareUsage -Executable *Chrome.exe -StartTime (get-date).AddHours(-5) | Where-Object {$_.User -eq 'Administrator'}

#endregion

#region Day 150

	# 20:01 - It`s time for Puppy. Why is it not streaming the output?
    Import-Module "$ModulesPath\SystemHelper" -RequiredVersion 1.0.0.5 -PassThru -Force
	Import-Module "$ModulesPath\SoftwareHelper" -RequiredVersion 1.0.0.7 -PassThru -OutVariable mod -Force
    $null = Set-PSBreakpoint -Script $mod.Path -Line 191
	psedit (Join-Path -Path $mod.ModuleBase -ChildPath 'SoftwareHelper.psd1')
	psedit (Join-Path -Path $mod.ModuleBase -ChildPath 'types\softwarehelper.format.ps1xml')

	Get-SoftwareUsage -Executable *Chrome.exe -StartTime (get-date).AddHours(-5)
	Get-SoftwareUsage -Executable *Chrome.exe -StartTime (get-date).AddHours(-5) | select -First 1
	Get-SoftwareUsage -Executable *Chrome.exe -StartTime (get-date).AddHours(-5) | Where-Object {$_.User -eq 'Administrator'}

#endregion

#region Demo Configuration

$ModulesPath = 'C:\Users\givanoad08\Source\Repos\events\s17e02 - PandP for Functions and Modules\Demo'
$ModulesPath = 'D:\GitHub\PUGbg\Events\s17e02 - PandP for Functions and Modules\Demo'
$BinariesPath = "$ModulesPath\SoftwareBinaries"

#endregion