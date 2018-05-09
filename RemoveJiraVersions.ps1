$user = "<Username>"
$pass = "<Password>"
$searchUri = "<JiraJQLUri>"
$versionTag = "<VersionTag>"

$pair = "${user}:${pass}"
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$base64 = [System.Convert]::ToBase64String($bytes)
$basicAuthValue = "Basic $base64"
$headers = @{}
$headers.Authorization = $basicAuthValue
$headers['Content-Type'] = 'application/json'

$search = Invoke-RestMethod -Uri $searchUri -Method Get -Headers $headers

$request = @{}
$request.update = @{}
$request.update.fixVersions = @()

$removeVersion = @{}
$removeVersion.remove = @{}
$removeVersion.remove.name = $versionTag
$removeVersion.remove = New-Object -TypeName PSObject -Prop $removeVersion.remove
$removeVersion = New-Object -TypeName PSObject -Prop $removeVersion

$request.update.fixVersions += $removeVersion
$request.update = New-Object -TypeName PSObject -Prop $request.update

$request = New-Object -TypeName PSObject -Prop $request
$json = ConvertTo-Json $request -Depth 100

foreach ($issue in $search.issues) {
    Invoke-RestMethod -Uri $issue.self -Method PUT -Headers $headers -Body $json > $null
}