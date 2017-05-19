#Why we need universal helper function for process execution to rule them all
# - Executables that do not work interactively
diskpart
# - Argument parsing
# - Output parsing

#region Demo Configuration

$ModulesPath = 'C:\Users\givanoad08\Source\Repos\events\s17e02 - PandP for Functions and Modules\Demo'
$BinariesPath = ''

#endregion

#region Day 1

    # 10:00 - I need to automate the ipconfig
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
    
#endregion

#region Day 21

    # 17:00 - New corporate policy arrived. It uninstalls Chrome and resets my html file associations to use IE.
    #         I decided to engineer-around it.

    # 17:59 - After short brainstorming I figured what I need:
    # - Ability to execute proccess both in Foreground and Background
    Import-Module "$ModulesPath\SomeModule" -RequiredVersion 1.0.0.3 -PassThru -Force
    Start-NewProcess -FilePath "$BinariesPath\Chrome.exe" -Arguments ''
    Start-NewProcess -FilePath "dism" -Arguments '' -Wait 

    # Outcome
    # - No Output
    # - Asynchronous execution

#endregion

#region Start-NewProcess v 1.0.0.4

    # UseCase
    # - Ability to start new processes

    $ModulesPath = 'C:\Users\gogbg\OneDrive\Learning\Microsoft\Seminars\pugbg\s17e02 - PandP for Functions and Modules\Demo'
    Import-Module "$ModulesPath\SomeModule" -RequiredVersion 1.0.0.4 -Force
    Start-NewProcess -FilePath C:\Windows\System32\ipconfig.exe -ArgumentList '/all' -Wait -ReturnResult

    # Outcome
    # - Not readable

#endregion