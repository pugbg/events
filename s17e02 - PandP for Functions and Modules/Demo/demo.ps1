#region Start-NewProcess v 1.0.0.1

    # UseCase
    # - Ability to start new processes

    $ModulesPath = 'C:\Users\gogbg\OneDrive\Learning\Microsoft\Seminars\pugbg\s17e02 - PandP for Functions and Modules\Demo'
    Import-Module "$ModulesPath\SomeModule" -RequiredVersion 1.0.0.1 -Force
    Start-NewProcess -FilePath C:\Windows\System32\ipconfig.exe -Arguments '/alll'

    # Outcome
    # - Flickering window
    # - No Output
    # - Asynchronous execution
    # - 

#endregion