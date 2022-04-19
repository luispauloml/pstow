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
}
