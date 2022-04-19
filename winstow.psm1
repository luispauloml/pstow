function winstow {
    [Cmdletbinding()]
    Param(
	[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
	[string]
	$Name
    )

    $pkg = Get-ChildItem -Filter $Name -Directory
    if (!$pkg) {
	Write-Error "$Name not found" -Category ObjectNotFound
    }
}
