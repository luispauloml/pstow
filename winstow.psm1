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
    Write-Verbose "found directory '$($pkg.Name)'"

    $contents = Get-ChildItem -Path $pkg
    if (!$contents) {
	Write-Verbose "'$Name is empty. Nothing to be done."
	return
    }

    # Check $TargetDir; an error will be thrown if it does not exists
    $Target = Resolve-Path -Path $Target

    # Now check whether it is a directory
    if ((Get-Item $Target).GetType().Name -ne "DirectoryInfo") {
	throw "$Target is not a directory"
    }
    Write-Verbose "found directory $Target"

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
	    Write-Verbose "'$($Item.Name)' does not exists at destination. Symbolic link created."
	    return

	} elseif ($FileExists -and !$isDir) {
	    Write-Error "'$($Item.Name)' already exists at $LinkPath" `
	      -Category WriteError
	}

	if ($isDir) {
	    Write-Verbose "'$Item' is a directory and already exists at destination."
 
	    $Contents = Get-ChildItem -Path $Item.FullName
	    if (!$Contents) {
		Write-Verbose "'$Item' is empty. Nothing to be done."
		return
	    }

	    $Subdir = Join-Path $Dir $Item.Name
	    $Contents | ForEach-Object {worker $PSITEM $Subdir}
	    return
	}
    }

    $contents | ForEach-Object {worker $PSITEM $Target}
}
