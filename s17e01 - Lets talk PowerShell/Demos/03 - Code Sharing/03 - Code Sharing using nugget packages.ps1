#region Finding Modules from PSGallery

Find-Module -Name typehelper -Repository PSgallery

Install-Module -Name typehelper -Repository PSgallery

#endregion

#region Automaticcally download missing RequiredModule 
Import-Module 'C:\Users\gogbg\OneDrive\Learning\Microsoft\Seminars\pugbg\s17e01 - Lets talk PowerShell\Demos\Modules\PSHelper' -Force
Import-Module 'C:\Users\gogbg\OneDrive\Learning\Microsoft\Seminars\pugbg\s17e01 - Lets talk PowerShell\Demos\Modules\PowerShellGet' -Force
Import-Module 'C:\Users\gogbg\OneDrive\Learning\Microsoft\Seminars\pugbg\s17e01 - Lets talk PowerShell\Demos\Modules\TypeHelper' -Force
Import-Module 'C:\Users\gogbg\OneDrive\Learning\Microsoft\Seminars\pugbg\s17e01 - Lets talk PowerShell\Demos\Modules\PSSolutionManagement' -Force

#New-SolutionConfiguration -Path 'C:\Users\gogbg\OneDrive\Learning\Microsoft\Seminars\pugbg\s17e01 - Lets talk PowerShell\Demos\Modules'

Build-Solution -SolutionConfigPath 'C:\Users\gogbg\OneDrive\Learning\Microsoft\Seminars\pugbg\s17e01 - Lets talk PowerShell\Demos\Modules' -Verbose
#endregion