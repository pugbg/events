#Why we need universal helper function for process execution to rule them all
# - Executables that do not work interactively
diskpart
# - Argument parsing
# - Output parsing

#region Demo Configuration

$ModulesPath = 'C:\Users\givanoad08\Source\Repos\events\s17e02 - PandP for Functions and Modules\Demo'
# $ModulesPath = 'D:\GitHub\PUGbg\Events\s17e02 - PandP for Functions and Modules\Demo'
$ScriptsPath = ''
$BinariesPath = ''

#endregion

#region Day 1

	### Point for us: How to start a process

    # 10:00 - I need to automate the iisreset
    Import-Module "$ModulesPath\SomeModule" -RequiredVersion 1.0.0.1 -PassThru -Force
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
    Import-Module "$ModulesPath\SomeModule" -RequiredVersion 1.0.0.2 -PassThru -Force
    Start-NewProcess -FilePath C:\Windows\System32\ipconfig.exe -Arguments '/alll'
	Start-NewProcess -FilePath C:\Windows\System32\ping.exe -Arguments '127.0.0.1'

    # Outcome:
    # - Exception is not displayed if it is not in the ErrorStream
    
	# 15:00 - Fixing the "Exception is not displayed if it is not in the ErrorStream"
	Import-Module "$ModulesPath\SomeModule" -RequiredVersion 1.0.0.3 -PassThru -Force
	Start-NewProcess -FilePath C:\Windows\System32\ipconfig.exe -Arguments '/alll'

#endregion

#region Day 21

    # 17:00 - New corporate policy arrived. It uninstalls Chrome and resets my html file associations to use IE.
    #         I decided to engineer-around it.

    # 17:59 - After short brainstorming I figured what I need:
    # - Ability to execute proccess both in Foreground and Background

	### Point for us: ParameterSet usage for multiple scenarios + Parameter Identification (switch and no switch)

    Import-Module "$ModulesPath\SomeModule" -RequiredVersion 1.0.0.4 -PassThru -Force
    Start-NewProcess -FilePath "$BinariesPath\Chrome.exe" -Arguments ''
    Start-NewProcess -FilePath "dism" -Arguments '' -WaitTimeout 30

    # Outcome
    # - Everything works!

#endregion

#region Day 22

    # 10:00 - On the next day, Konstantin saw what I`ve did, and wanted to use my module, so I`ve decided to:
    # - Implement validation of the input parameters
	# - Implement generic error handling
	# - Add Verbose logging so he can see what it is doing if he wants.
	# - Rename the module so it is easier to understand the purpose of the commands inside it

	### Point for us: InputValidation + Generic Error handling + Streams

    Import-Module "$ModulesPath\SystemHelper" -RequiredVersion 1.0.0.5 -PassThru -Force 
    Start-NewProcess -FilePath "$BinariesPath\Chrome2.exe" -Arguments '' -Wait 9999
	Start-NewProcess -FilePath "$BinariesPath\Chrome2.exe" -Arguments '' -Wait 60
	Start-NewProcess -FilePath "$BinariesPath\Chrome.exe" -Arguments '' -Wait 60
	Start-NewProcess -FilePath "$BinariesPath\Chrome.exe" -Arguments '' -Wait 60 -Verbose

    # Outcome
    # - I`ve testad and gave the module to Konstantin

#endregion

#region Day 40

	### Point for us: Module Interdependency + ...

    # 10:00 - On the next day, Konstantin came with the proposal to make a universal script 
	#         to configure the computer as we want it to be. We`ve dicussed it and 
	#         came with the conclusion that:
	# - We should make SoftwareHelper module that is responsible for each software installation and detection method
	# - Should support being rerun several times
	Import-Module "$ModulesPath\SoftwareHelper" -RequiredVersion 1.0.0.1 -PassThru -Force
	psedit "$ScriptsPath\configure_mypc.ps1"
    & "$ScriptsPath\configure_mypc.ps1" -Verbose
	& "$ScriptsPath\configure_mypc.ps1" -Skip 'ChromeInstallation' -Verbose

#endregion

#region Day 42

	### Point for us: OutputType + Custom Formatting

    # 10:00 - We want to implement the functionality to return the result of the operation
    Import-Module "$ModulesPath\SoftwareHelper" -RequiredVersion 1.0.0.2 -PassThru -Force
	$Chrome = Install-Chrome -BinPath '' -PassThru

	# 12:00 - We want to implement the functionality to return the result of the operation
    Import-Module "$ModulesPath\SoftwareHelper" -RequiredVersion 1.0.0.3 -PassThru -Force
	Install-Chrome -BinPath '' -PassThru
	Install-Chrome -BinPath '' -PassThru | Where-Object {$_.Status -eq 'Failed'}
		
#endregion

#region Day 43

	### Point for us: Streaming the result thru the Pipeline
	Get-WinEvent -FilterHashtable @{Logname='System';Id=7036} -MaxEvents 4 | select -First 1

	# 10:00 - I want to see the Chrome Executions
	Import-Module "$ModulesPath\SoftwareHelper" -RequiredVersion 1.0.0.4 -PassThru -Force


	# 14:00 - 
	# - Make it work faster 
	Import-Module "$ModulesPath\SoftwareHelper" -RequiredVersion 1.0.0.7 -PassThru -Force

	# 17:00 - 
	# - Make it work even faster 
	Import-Module "$ModulesPath\SoftwareHelper" -RequiredVersion 1.0.0.8 -PassThru -Force

	# 18:00
	# - Make it work against remote computers

#endregion