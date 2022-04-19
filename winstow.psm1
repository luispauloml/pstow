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
	Write-Error "$Name not found" -Category ObjectNotFound
    }

    $contents = Get-ChildItem -Path $pkg
    if (!$contents) {
	Write-Verbose "$Name is empty"
	return
    }

    # Check $TargetDir; an error will be thrown if it does not exists
    $Target = Resolve-Path -Path $Target
}
