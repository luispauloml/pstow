function winstow {
    [Cmdletbinding(SupportsShouldProcess=$true)]
    Param(
	[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
	[string]
	$PkgName,
	[Parameter(Mandatory=$true)]
	[string]
	$Destination,
	[Parameter()]
	[switch]
	$Force
    )

    if ($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $true) {
	$VerbosePreference = "Continue"
    }

    $Pkg = Get-ChildItem -Filter $PkgName -Directory
    if (!$Pkg) {
	throw "$PkgName not found"
    } elseif ($Pkg.Length -ne 1) {
	Write-Error "more than one item was found for '$PkgName'" `
	  -Category LimitsExceeded
    }
    $Pkg = $Pkg[0]
    Write-Verbose "found directory '$($Pkg.Name)'"

    $Contents = Get-ChildItem -Path $Pkg
    if (!$Contents) {
	Write-Verbose "'$PkgName' is empty. Nothing to be done."
	return
    }

    # Check $Destination; an error will be thrown if it does not exists
    $Destination = Resolve-Path -Path $Destination

    # Now check whether it is a directory
    if ((Get-Item $Destination).GetType().Name -ne "DirectoryInfo") {
	throw "$Destination is not a directory"
    }
    Write-Verbose "found directory $Destination"

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
	if (($isDir -and !$FileExists) -or (!$isDir -and (($FileExists -and $Force.IsPresent) -or !$FileExists))) {
		 if ($Force.IsPresent -and $FileExists) {
		     Write-Warning "'$($Item.Name)' already exists and will be overwritten with a symbolic link."
		 } else {
		     Write-Verbose "'$($Item.Name)' does not exists at destination. Symbolic link will be created." }

	    New-Item -ItemType SymbolicLink `
	      -Path $LinkPath -Target $Item.FullName `
	      -Force | Out-Null
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

	    $isAlreadyLink = !!("Junction", "SymbolicLink", "HardLink" | `
	      Where-Object {$_ -eq (Get-Item -Path $LinkPath).LinkType})
	    if ($isAlreadyLink) {
		Write-Verbose "'$($Item.Name)' is already a reference to another location."

		if ($Force.isPresent) {
		    Write-Warning "'$($Item.Name)' will be overwritten by a symbolic link."
		    New-Item -ItemType SymbolicLink `
		      -Path $LinkPath -Target $Item.FullName `
		      -Force | Out-Null
		    return

		} else {
		    Write-Error "'$($Item.Name)' already exists at $LinkPath" `
		      -Category WriteError
		}

	    } else {
		$Subdir = Join-Path $Dir $Item.Name
		$Contents | ForEach-Object {worker $PSITEM $Subdir}
		return
	    }
	}
    }

    $Contents | ForEach-Object {worker $PSITEM $Destination}
}
