# PStow - Create symbolic links in Windows with PowerShell like it is GNU Stow
# Copyright (c) 2022 Luis Paulo Morais Lima <luispauloml at gmail dot com>
#
# This file is part of PStow.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

<#
.SYNOPSIS
Setup symbolic links for files.

.DESCRIPTION
Creates symbolics for files and directories in a fashion similar to GNU Stow.

It traverses the content in the directory `PkgName` and create links
in `Destination` as necessary.  If it finds a directory inside
`PkgName` that does not exists in `Destination`, it creates a link for
it in `Destination` instead of creating a folder and recursively
creating links for its child-items.

.PARAMETER PkgName
The name of a directory inside current working directory whose
contents will serve as a target for the links to be created.

.PARAMETER Destination
A path to the directory in which the links will be created.

.PARAMETER Force
If given, existing files -- not directories -- will be overwritten by
a symbolic link.

If given, existing references for directories -- junction, hard link
or symbolic link to a directory -- will be overwritten by a new
symbolic link.

If not given and a file or reference to directory already exists at
destination, an error will be written to the error stream for that
item but execution will not be terminated.

.PARAMETER WhatIf
Does not execute any change, only shows what would happen.

.PARAMETER Confirm
Asks for confirmation before creating a symbolic link.

.NOTES
- Set-PStow does not create hard links, nor junctions, only symbolic
  links.

- Passing -Force will not override -Confirm.

.EXAMPLE
Set-PStow emacs $env:APPDATA -Verbose -WhatIf -Force
VERBOSE: found directory 'emacs'
VERBOSE: found directory C:\Users\<user>\AppData\Roaming
VERBOSE: '.emacs.d' is a directory and already exists at destination.
VERBOSE: 'lisp' is a directory and already exists at destination.
VERBOSE: 'lisp' is already a reference to another location.
WARNING: 'lisp' will be overwritten by a symbolic link.
What if: Performing the operation "Create Symbolic Link" on target "Destination: C:\Users\<user>\AppData\Roaming\.emacs.d\lisp".
WARNING: 'init.el' already exists and will be overwritten with a symbolic link.
What if: Performing the operation "Create Symbolic Link" on target "Destination: C:\Users\<user>\AppData\Roaming\.emacs.d\init.el".
#>
function Set-PStow {
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

New-Alias -Name "pstow" -Value "Set-PStow"
