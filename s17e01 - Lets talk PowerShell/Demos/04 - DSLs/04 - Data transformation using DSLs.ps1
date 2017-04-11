#region Positional parameters

Function Fun1
{

    param
    (
        [Parameter(Mandatory=$true,Position=1)]
        [string]$Param1,

        [Parameter(Mandatory=$true,Position=2)]
        [string]$Param2
    )

    process
    {

        "Param1 is $Param1, Param2 is $Param2"

    }

}

Fun1 Value1 Value2

#endregion

#region Output streaming

Function Fun1
{

    param
    (
        [Parameter(Mandatory=$true,Position=1)]
        [string]$Param1,

        [Parameter(Mandatory=$true,Position=2)]
        [string]$Param2
    )

    process
    {

        "Param1 is $Param1"
        "Param2 is $Param2"

    }

}

$result = Fun1 Value1 Value2

#endregion

#region ScriptBlock parameters

Function Fun1
{

    param
    (
        [Parameter(Mandatory=$true,Position=1)]
        [scriptblock]$Param1
    )

    process
    {

        Invoke-Command -ScriptBlock $Param1 -NoNewScope

    }

}

Fun1 {get-date}

#endregion

#region Simple DSL

Function AsciiPic
{

    param
    (
        [Parameter(Mandatory=$true,Position=1)]
        [scriptblock]$Param1
    )

    process
    {

        #Internal Functions that will act as keywords
        Function kitten
        {
            process
            {
                @'

  (.   \
    \  |   
     \ |___(\--/)
   __/    (  . . )
  "'._.    '-.O.'
       '-.  \ "|\
          '.,,/'.,,mrf

'@
            }
        }

        Function Mouse
        {
            process
            {
                @'

      \    /\
       )  ( ')
      (  /  )
       \(__)|

'@
            }
        }

        Function pugbg
        {
            process
            {
                @'

|_   __ |_   _||_   _.' ___  [  |             
  | |__) || |    | |/ .'   \_|| |.--.  .--./) 
  |  ___/ | '    ' || |   ____| '/'`\ / /'`\; 
 _| |_     \ \__/ / \ `.___]  |  \__/ \ \._// 
|_____|     `.__.'   `._____.[__;.__.'.',__`  
                                     ( ( __))

'@
            }
        }

        Function love
        {
            process
            {
                @'

[  |                     
 | | .--.  _   __ .---.  
 | / .'`\ [ \ [  / /__\\ 
 | | \__. |\ \/ /| \__., 
[___'.__.'  \__/  '.__.' 

'@
            }
        }

        Invoke-Command -ScriptBlock $Param1 -NoNewScope

    }

}

cls

AsciiPic {
    kitten
    love
    mouse
}

#endregion

#region html-tables DSL

Import-Module -FullyQualifiedName 'C:\Users\gogbg\OneDrive\Learning\Microsoft\Seminars\pugbg\s17e01 - Lets talk PowerShell\Demos\Modules\AstHelper' -Force
Import-Module -FullyQualifiedName 'C:\Users\gogbg\OneDrive\Learning\Microsoft\Seminars\pugbg\s17e01 - Lets talk PowerShell\Demos\Modules\ReportingHelper' -Force

$Services = Get-CimInstance -ClassName Win32_Service

$htmlResult = htmldoc {

    table {

        foreach ($svc in $Services)
        {
            table-row {
                table-column Name @{} { $svc.Name }
                table-column State @{
                    class=$(if ($svc.StartMode -eq 'Auto' -and $svc.State -eq 'Stopped') { 'error' } else {'ok-text'})
                } { $svc.State }
                table-column StartMode @{} { $svc.StartMode }
                table-column ProcessInfo @{} {
                    $Proc = Get-Process -Id $svc.processid
                    if ($Proc.Id -ne 0)
                    {
                        paragraph @{} { "ProcessId=" + $Proc.Id }
                        paragraph @{} { "ProcessName=" + $Proc.Name }
                        paragraph @{} { "ProcessMemory=" + "$($Proc.WorkingSet / 1MB) MB" }
                    }
                }
                table-column Dependacies @{width='300px'} {
                    $SvcInfo = Get-Service -Name $svc.Name
                    foreach ($s in $SvcInfo.DependentServices)
                    {
                        Table-row {
                            table-column Name @{width='200px'} {$s.Name}
                            table-column Status @{width='100px'} {$s.Status}
                        }
                    }
                }
            }
        }
    }

}

#Save the html in file and open it
$newTempFile = New-TemporaryFile
$newTempFile = Rename-Item -Path $newTempFile -NewName ($newTempFile.BaseName + '.html') -PassThru
Out-File -FilePath $newTempFile -InputObject $htmlResult -Force
& $newTempFile

#endregion