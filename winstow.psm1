function winstow {
    [Cmdletbinding()]
    Param(
	[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
	[string]
	$Name
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
}
