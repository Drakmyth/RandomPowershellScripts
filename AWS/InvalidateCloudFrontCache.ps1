# ---------------------------------------------------------------
# Remove this section if running script as an Octopus Deploy step
$CFAccessKey = '<AccessKey>'
$CFSecretKey = '<SecretKey>'
$CFRegion = '<Region>'
$CFAlias = '<DomainName>'
$Paths = '/<Route>'
# ---------------------------------------------------------------

Import-Module AWSPowerShell

$distroList = Get-CFDistributionList -AccessKey $CFAccessKey -SecretKey $CFSecretKey -Region $CFRegion
$distro = $distroList.Items | Where-Object { ($_.Aliases.Items | Where-Object { $_ -eq $CFAlias }) }
$Paths = $Paths.Split(' ')

$fullPaths = @()
ForEach ($alias in $distro.Aliases.Items) {
    ForEach ($path in $Paths) {
        $fullPaths += "$($alias)$($path)"
    }
}
$fullPaths = [string]::Join(', ', $fullPaths)

Write-Host "Invalidating CloudFront Distribution $($distro.Id) ($($fullPaths))..."
Write-Host 'This may take up to 20 minutes.'

New-CFInvalidation $distro.Id -Paths_Item $Paths -InvalidationBatch_CallerReference (Get-Date -Format o) -Paths_Quantity $Paths.Count -AccessKey $CFAccessKey -SecretKey $CFSecretKey -Region $CFRegion