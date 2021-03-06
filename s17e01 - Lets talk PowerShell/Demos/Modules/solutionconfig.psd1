$UserVariables = @{
}

$SolutionStructure=@{
	#Example: @(@{SourcePath='c:\modules;BuildPath='c:\modules bin'})
	ModulesPath=@(
        @{
            SourcePath='C:\Users\gogbg\OneDrive\Learning\Microsoft\Seminars\pugbg\s17e01 - Lets talk PowerShell\Demos\Modules'
            BuildPath='C:\Users\gogbg\OneDrive\Learning\Microsoft\Seminars\pugbg\s17e01 - Lets talk PowerShell\Demos\Modules bin'
        }
    )
}
$Build=@{
	AutoloadbuiltModulesForUser=$false
	AutoResolveDependantModules=$false
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

