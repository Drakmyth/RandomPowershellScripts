# ---------------------------------------------------------------
# Remove this section if running script as an Octopus Deploy step
$AGAccessKey = "<AccessKey>"
$AGSecretKey = "<SecretKey>"
$AGRegion = "<Region>"
$CloudFormationStackName = "<StackName>"
$AGStageName = "<StageName>"
# ---------------------------------------------------------------

Import-Module AWSPowerShell

#Set up the credentials and the dependencies
$credential = New-AWSCredentials -AccessKey $AGAccessKey -SecretKey $AGSecretKey
$stack = Get-CFNStack -StackName $CloudFormationStackName -Credential $credential -Region $AGRegion

$apiGatewayRestApiId = $stack.Outputs.Where({ $_.OutputKey -eq "RestApiId" }).OutputValue
Write-Output "RestApiId: $apiGatewayRestApiId"

#Remove existing API Gateway Stage
Remove-AGStage -RestApiId $apiGatewayRestApiId -StageName $AGStageName -Credential $credential -Region $AGRegion

#Deploy Updated API Gateway Stage
New-AGDeployment -RestApiId $apiGatewayRestApiId -StageName $AGStageName -Credential $credential -Region $AGRegion