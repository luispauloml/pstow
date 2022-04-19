function winstow {
    [Cmdletbinding()]
    Param(
	[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
	[string]
	$Name,
	[Parameter(Mandatory=$true)]
	[string]
	$Target
    )

    if ($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $true) {
	$VerbosePreference = "Continue"
    }

    $pkg = Get-ChildItem -Filter $Name -Directory
    if (!$pkg) {
	throw "$Name not found"
    } elseif ($pkg.Length -ne 1) {
	Write-Error "more than one item was found for '$Name'" `
	  -Category LimitsExceeded
    }
    $pkg = $pkg[0]

    $contents = Get-ChildItem -Path $pkg
    if (!$contents) {
	Write-Verbose "$Name is empty"
	return
    }

    # Check $TargetDir; an error will be thrown if it does not exists
    $Target = Resolve-Path -Path $Target

    # Recursively create symbolic links
    function worker($Item, $Dir){
	switch($item.GetType().Name) {
	    {$_ -eq "DirectoryInfo"}
	    {$isDir = $true}

	    {$_ -eq "FileInfo"}
	    {$isDir = $false}

	    default
	    {Write-Error "something that is neither a file nor a directory was found : '$($item.FullName)' of type '$($item.GetType().Name)'"}
	}

	$LinkPath = Join-Path $Dir $Item.Name
	$FileExists = Test-Path -Path $LinkPath
	if (!$FileExists) {
	    New-Item -ItemType SymbolicLink `
	      -Path $LinkPath -Target $Item.FullName
	    Write-Verbose "target does not exists; symbolic link created for '$($item.Name)'"
	    return
	} else {
	    Write-Error "$($item.Name) already exists at $linkPath" `
	      -Category WriteError
	}

	if ($isDir) {
	    Write-Verbose "$item is a directory"
	    $Contents = Get-ChildItem -Path $Item
	    $Subdir = Join-Path $Dir $Item.Name
	    $Contents | ForEach-Object {worker $PSITEM $Subdir}
	    return
	}
    }

    $contents | ForEach-Object {worker $PSITEM $Target}
}
