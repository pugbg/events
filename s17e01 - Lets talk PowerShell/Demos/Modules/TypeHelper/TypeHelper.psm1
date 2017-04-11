function ConvertTo-String
{
  [CmdletBinding()]
  param
  (
        [Parameter(Mandatory=$true)]
        [ValidateScript({
            If ('Hashtable','OrderedDictionary','AXNodeConfiguration','PSBoundParametersDictionary' -contains $_.GetType().Name)
            {
                $true
            }
            else
            {
                throw "Supported InputTypes are 'Hashtable' and 'OrderedDictionary'"
            }
        })]
        $InputObject,

        [Parameter(Mandatory=$false)]
        [switch]$DoNotFormat
    )
  
    Begin
    {
        function priv_Escape-SpecialChars
        {  
            param
            (
                [Parameter(Mandatory=$true, Position = 0)]
                [AllowEmptyString()]
                [string]$InputObject
            )

            if([string]::IsNullOrEmpty($InputObject))
            {
                return ""
            }
            else
            {
                [string]$ParsedText = $InputObject

                if($ParsedText.ToCharArray() -icontains "'")
                {
                    $ParsedText = $ParsedText -replace "'","''"
                }

                return $ParsedText
            }
        }
    }

    Process
    {
        $sb = new-object System.Text.StringBuilder

        $null = $sb.AppendLine('@{')

        foreach ($key in $InputObject.Keys)
        {
		    if ($InputObject[$key])
		    {
			    switch ($inputObject[$key].GetType().Name)
			    {
                    ### ScriptBlocks
			        'ScriptBlock' {
				        $null = $sb.AppendLine("$key = `{$($inputObject[$key].ToString())`}")
				        break
			        }

                    ### Strings and Enums
			        { @('String','ActionPreference') -contains $_ }  { 
                        [string]$itemText = "{0} = '{1}'" -f "$key", $(priv_Escape-SpecialChars -InputObject $inputObject[$key])
				        $null = $sb.AppendLine($itemText)
				        break
			        }

                    ### String Arrays
			        'String[]' {
                        [string]$itemText = "{0} = @({1})" -f "$key", "$($($inputObject[$key] | foreach { "'$(priv_Escape-SpecialChars -InputObject $_)'" }) -join ", ")"
				        $null = $sb.AppendLine($itemText)
				        break
			        }

                    ### Numerics
			        { ($_ -ilike '*int*') -or (@('single','double','decimal','SByte','Byte') -icontains $_) } {
                        [string]$itemText = "{0} = {1}" -f "$key", $($inputObject[$key]).ToString()
				        $null = $sb.AppendLine($itemText)
				        break
			        }

                    ### Nested Hashtables (recursive call)
			        {'Hashtable','OrderedDictionary','PSBoundParametersDictionary' -contains $_}  { 
                        [string]$itemText = "{0} = {1}" -f "$key", $(ConvertTo-String -InputObject $inputObject[$key] -DoNotFormat)
				        $null = $sb.AppendLine($itemText) 
				        break
			        }

                    ### Nested Hashtable Arrays (recursive call)
			        {'Hashtable[]','OrderedDictionary[]','PSBoundParametersDictionary[]' -contains $_}  { 
						$NewLineStr = [Environment]::NewLine
						$JoinSeparator = ",$NewLineStr"
                        [string]$itemText = "{0} = @($NewLineStr{1}$NewLineStr)" -f "$key", "$($($inputObject[$key] | foreach { ConvertTo-String -InputObject $_ -DoNotFormat }) -join $JoinSeparator)"
				        $null = $sb.AppendLine($itemText)
				        break
			        }

                    ### Booleans and Switches
                    { @('Boolean','SwitchParameter') -contains $_ } {
                        [string]$itemText = '{0} = ${1}' -f "$key", $($inputObject[$key].ToString())
				        $null = $sb.AppendLine($itemText)
				        break
			        }

                    ### PSCustomObject (NoteProperties only)
                    'PSCustomObject' {
                        # Convert to hashtable
                        $propHash = @{}
                        foreach ($prop in $inputObject[$key].PSObject.Properties)
                        {
                            $propHash[$prop.Name] = $prop.Value
                        }

                        [string]$itemText = '{0} = $([PSCustomObject] {1})' -f "$key", $(ConvertTo-String -InputObject $propHash -DoNotFormat)
				        $null = $sb.AppendLine($itemText) 
				        break
			        }

                    ### DateTime
                    'DateTime' {
                        [string]$itemText = "{0} = '{1}'" -f "$key", $($inputObject[$key].ToUniversalTime().ToString("dd.MM.yyyy HH.mm:ss UTC", [CultureInfo]::InvariantCulture))
				        $null = $sb.AppendLine($itemText) 
				        break
			        }

			        Default {
				        Write-Warning "Serializing not supported key: $key that contains: $_"
                        [string]$itemText = '{0} = {1}' -f "$key", $($inputObject[$key].ToString())
				        $null = $sb.AppendLine($itemText)
			        }
			    }
		    }
		    else
		    {
				$null = $sb.AppendLine('{0} = $null' -f "$key")
		    }
        }

        $null =  $sb.AppendLine('}')
    
        $result = $sb.ToString()

        if($DoNotFormat.IsPresent)
        {
            $result.Trim([environment]::NewLine)
        }
        else
        {
            ConvertTo-TabifiedString -ScriptText $result
        }
    }

    End
    {

    }
}

function ConvertTo-Hashtable
{

	param
	(
		[ValidateScript({
        $TempParam = $_
		switch ($TempParam.GetType().Fullname)
		{
			'System.String' {
				try
				{
					$obj = ConvertFrom-Json -InputObject $TempParam -ErrorAction Stop
					$Script:InputObjectData = $obj.psobject.Properties
				}
				catch
				{
					throw "InputObject is not a valid json string"
				}
				break
			}
			default {
				$Script:InputObjectData = $TempParam.psobject.Properties
			}
		}
		$true
	})]
		$InputObject
	)

	begin
	{
		$DepthThreshold = 32

		function Get-IOProperty
		{
			param
			(
				[Parameter(Mandatory=$true)]
				[System.Management.Automation.PSPropertyInfo[]]$Property,

				[Parameter(Mandatory=$true)]
				[int]$CurrentDepth
			)
			
			#Increse and chech Depth
			$CurrentDepth++
			if ($Function:Depth -ge $DepthThreshold)
			{
				Write-Error -Message "Converting to Hashtable reached Depth Threshold of 32 on $($Property.Name -join ',')" -ErrorAction Stop
			}

			$Ht = [hashtable]@{}
			foreach ($Prop in $Property)
			{
				if ($Prop.Value)
				{
					switch ($Prop.TypeNameOfValue)
					{
						'System.String' {
							$ht.Add($Prop.Name,$Prop.Value)
							break
						}
						'System.Boolean' {
							$ht.Add($Prop.Name,$Prop.Value)
							break
						}
						'System.DateTime' {
							$ht.Add($Prop.Name,$Prop.Value.ToString())
							break
						}
						{$_ -ilike '*int*'} {
							$ht.Add($Prop.Name,$Prop.Value)
							break
						}
						default {
							$ht.Add($Prop.Name,(Get-IOProperty -Property $Prop.Value.psobject.Properties -CurrentDepth $CurrentDepth))
						}
					}
				}
				else
				{
					$ht.Add($Prop.Name,$null)
				}
			}
			$Ht
		}
	}
  
	process
	{
		$CurrentDepth = 0
		Get-IOProperty -Property $InputObjectData -CurrentDepth $CurrentDepth
	}
  
	end
	{
	}
}

function ConvertTo-TabifiedString
{
	[CmdletBinding()]
	Param
	(
		$ScriptText
	) 
	
	$CurrentLevel = 0
	$ParseError = $null
	$Tokens = $null
	$AST = [System.Management.Automation.Language.Parser]::ParseInput($ScriptText, [ref]$Tokens, [ref]$ParseError) 
	
	if($ParseError) { 
	$ParseError | Write-Error
	throw 'The parser will not work properly with errors in the script, please modify based on the above errors and retry.'
	}
	
	for($t = $Tokens.Count -2; $t -ge 1; $t--) {
		
	$Token = $Tokens[$t]
	$NextToken = $Tokens[$t-1]
		
	if ($token.Kind -match '(L|At)Curly') { 
		$CurrentLevel-- 
	}  
		
	if ($NextToken.Kind -eq 'NewLine' ) {
		# Grab Placeholders for the Space Between the New Line and the next token.
		$RemoveStart = $NextToken.Extent.EndOffset  
		$RemoveEnd = $Token.Extent.StartOffset - $RemoveStart
		$tabText = "`t" * $CurrentLevel 
		$ScriptText = $ScriptText.Remove($RemoveStart,$RemoveEnd).Insert($RemoveStart,$tabText)
	}
		
	if ($token.Kind -eq 'RCurly') { 
		$CurrentLevel++ 
	}     
	}

	$ScriptText
}

function Resolve-ObjectProperty
{
    [CmdletBinding()]
    [OutputType([object])]
    param
    (
        #InputObject
        [Parameter(Mandatory=$true,ParameterSetName='NoRemoting_Default')]
        [object[]]$InputObject,

        #PropertyName
        [Parameter(Mandatory=$true,ParameterSetName='NoRemoting_Default')]
        [string]$PropertyName,

		#PropertyValueReference
        [Parameter(Mandatory=$true,ParameterSetName='NoRemoting_Default')]
        [hashtable]$PropertyValueReference
    )
    
    Begin
    {
          
    }

    Process
    {
		foreach ($object in $InputObject)
		{
			if ($object.psobject.Properties.Name -contains $PropertyName)
			{
				if ($PropertyValueReference.ContainsKey(($object.$PropertyName)))
				{
					$object.$PropertyName = $PropertyValueReference[$object.$PropertyName]			
				}
			}
		}
		$InputObject
    }

    End
    {

    }
}

function Import-PSDataFile
{
    [CmdletBinding()]
    Param 
	(
        [Parameter(Mandatory)]
        [Microsoft.PowerShell.DesiredStateConfiguration.ArgumentToConfigurationDataTransformation()]
        [hashtable] $FilePath    
    )
    return $FilePath
}

function ConvertFrom-JsonString
{
    [CmdletBinding()]
    param
    (
        #InputObject
        [Parameter(Mandatory=$true,ParameterSetName='NoRemoting_Default')]
        $InputObject
    )
    
    Begin
    {
          
    }

    Process
    {
		    add-type -assembly system.web.extensions
			$ps_js = New-Object system.web.script.serialization.javascriptSerializer -ErrorAction Stop
            $ps_js.DeserializeObject($InputObject) | foreach {
                New-Object -TypeName psobject -Property $_ -ErrorAction Stop
            }
			
    }

    End
    {

    }
}

function New-DynamicConfiguration
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        #Definition
        [Parameter(Mandatory=$true,Position=0,ParameterSetName='NoRemoting_Default')]
        [scriptblock]$Definition
    )
    
    Begin
    {
          
    }

    process
	{
		$blockDefinition = $Definition.ToString() + "`n" + 'Export-ModuleMember -Variable *'
		$result = . New-Module -AsCustomObject -ScriptBlock ([scriptblock]::Create($blockDefinition))
		$SubProperties = $result.psobject.Properties | Where-Object {$_.TypeNameOfValue -eq 'System.Management.Automation.ScriptBlock'} -ErrorAction Stop
		foreach ($item in $SubProperties)
		{
			$result."$($item.Name)" = New-DynamicConfiguration -Definition $result."$($item.Name)" -ErrorAction Stop
		}
		$result
	}

    End
    {

    }
}