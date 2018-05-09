# ---------------------------------------------------------------
# Remove this section if running script as an Octopus Deploy step
$CFAccessKey = "<AccessKey>"
$CFSecretKey = "<SecretKey>"
$CFRegion = "<Region>"
$CFStackName = "<StackName>"
$UseS3ForCloudFormationTemplate = $true
$UseS3ForStackPolicy = $false
$CloudFormationTemplateURI = "<S3TemplateUri>"
$CloudFormationStackPolicyURI = ""
$CloudFormationCapability = "CAPABILITY_IAM"
$CloudFormationOnFailure = "ROLLBACK"
$UpdateExistingStack = $true
$DeleteExistingStack = $false
$CloudFormationParameters = '
{
"Key": "Value"
}
'
# ---------------------------------------------------------------

#Check for the PowerShell cmdlets
try {
    Import-Module AWSPowerShell -ErrorAction Stop
}
catch {
    throw "AWSPowerShell module not installed"
}

function Confirm-CFNStackDeleted($credential, $stackName) {

    do {
        $stack = $null
        try {
            $stack = Get-CFNStack -StackName $CFStackName -Credential $credential -Region $CFRegion
        }
        catch {}

        if ($stack -ne $null) {
            $stack | ForEach-Object {
                $progress = $_.StackStatus.ToString()
                $name = $_.StackName.ToString()

                Write-Host "Waiting for stack to deleted. Status: $progress"

                if ($progress -ne "DELETE_COMPLETE" -and $progress -ne "DELETE_IN_PROGRESS") {
                    Write-Host ($stack | Format-List | Out-String)
                    throw "Something went wrong deleting the CloudFormation Stack"
                }
            }

            Start-Sleep -s 15
        }
    }until ($stack -eq $null)
}

function Confirm-CFNStackCompleted($credential, $stackName, $region) {
    $stackSuccessStatuses = @("CREATE_COMPLETE", "UPDATE_COMPLETE")
    $stackPendingStatuses = @("CREATE_IN_PROGRESS", "DELETE_IN_PROGRESS", "DELETE_COMPLETE", "REVIEW_IN_PROGRESS", "UPDATE_IN_PROGRESS", "UPDATE_COMPLETE_CLEANUP_IN_PROGRESS")

    $complete = $false
    do {
        $stack = Get-CFNStack -StackName $stackName -Credential $credential -Region $region

        #Depending on the template sometimes there are multiple status per CFN template
        $stack | ForEach-Object {
            $progress = $_.StackStatus.ToString()
            $name = $_.StackName.ToString()

            Write-Host "Waiting for stack to be created/updated. Status: $progress"

            if (-not $stackSuccessStatuses.Contains($progress) -and -not $stackPendingStatuses.Contains($progress)) {
                Write-Host ($stack | Format-List | Out-String)
                throw "Something went wrong creating/updating the CloudFormation Stack"
            }
        }

        $inProgress = $stack | Where-Object { $stackPendingStatuses.Contains($_.StackStatus.ToString()) }

        if ($inProgress.Count -eq 0) {
            $complete = $true
        }
        else {
            Start-Sleep -s 15
        }
    }until ($complete -eq $true)
}

function Create-ChangeSet($credential) {
    $changeSetName = "c-$((Get-Date).ToString("yyyy-MM-dd-HH-mm-ss"))"
    Write-Host "Creating Stack ChangeSet $changeSetName..."
    New-CFNChangeSet -Credential $credential -TemplateUrl $CloudFormationTemplateURI -StackName $CFStackName -ChangeSetName $changeSetName -Region $CFRegion -Parameter $cloudFormationParams -Capability $CloudFormationCapability
}

function Test-ChangeSet($credential, $changeSetArn) {
    $changeSetSuccessStatuses = @("CREATE_COMPLETE")
    $changeSetPendingStatuses = @("CREATE_IN_PROGRESS", "CREATE_PENDING")

    $complete = $false
    do {
        $changeSet = Get-CFNChangeSet -Credential $credential -StackName $CFStackName -ChangeSetName $changesetArn -Region $CFRegion
        $progress = $changeSet.Status.Value

        Write-Host "Waiting for ChangeSet creation to complete. Status: $progress"
        if ($changeSetSuccessStatuses.Contains($progress)) {
            $complete = $true
        }
        elseif ($changeSetPendingStatuses.Contains($progress)) {
            Start-Sleep -s 5
        }
        else {
            # An error may have occurred, but most likely there are just no required changes
            $complete = $true
        }
    } until ($complete -eq $true)

    return $changeSet.ExecutionStatus -eq "AVAILABLE"
}

function Update-Stack($credential) {
    $changeSetArn = Create-ChangeSet -credential $credential
    $needsUpdate = Test-ChangeSet -credential $credential -changeSetArn $changeSetArn
    Write-Host "Stack $CFStackName requires update: $needsUpdate"

    if ($needsUpdate -eq $true) {
        Write-Host "Beginning Stack Update..."
        Start-CFNChangeSet -Credential $credential -ChangeSetName $changeSetArn -StackName $CFStackName -Region $CFRegion
    }
}

# Check the parameters.
if (-NOT $CFAccessKey) { throw "You must enter a value for 'Access Key'." }
if (-NOT $CFSecretKey) { throw "You must enter a value for 'Secret Key'." }
if (-NOT $CFRegion) { throw "You must enter a value for 'Region'." }
if (-NOT $CFStackName) { throw "You must enter a value for 'Stack Name'." }
if ($DeleteExistingStack -eq $true -and $UpdateExistingStack -eq $true) { throw "'Delete Existing Stack' and 'Update Existing Stack' are mutually exclusive." }

#Reformat the CloudFormation parameters
$paramObject = ConvertFrom-Json $CloudFormationParameters
$cloudFormationParams = @()

$paramObject.psobject.properties | ForEach-Object {
    $keyPair = New-Object -Type Amazon.CloudFormation.Model.Parameter
    $keyPair.ParameterKey = $_.Name
    $keyPair.ParameterValue = $_.Value

    $cloudFormationParams += $keyPair
}

Write-Output "--------------------------------------------------"
Write-Output "Region: $CFRegion"
Write-Output "CloudFormation Stack Name: $CFStackName"
Write-Output "Use S3 for CloudFormation Script?: $UseS3ForCloudFormationTemplate"
Write-Output "Use S3 for CloudFormation Stack Policy?: $UseS3ForStackPolicy"
Write-Output "CloudFormation Script Url: $CloudFormationTemplateURI"
Write-Output "CloudFormation Stack Policy Url: $CloudFormationStackPolicyURI"
Write-Output "CloudFormation Capability: $CloudFormationCapability"
Write-Output "CloudFormation On Failure: $CloudFormationOnFailure"
Write-Output "Update Existing Stack On Conflict: $UpdateExistingStack"
Write-Output "Delete Existing Stack On Conflict: $DeleteExistingStack"
Write-Output "CloudFormation Parameters:"
Write-Output $cloudFormationParams
Write-Output "--------------------------------------------------"

#Set up the credentials and the dependencies
Set-DefaultAWSRegion -Region $CFRegion
$credential = New-AWSCredentials -AccessKey $CFAccessKey -SecretKey $CFSecretKey

#Check to see if the stack exists
try {
    Write-Host "Processing CloudFormation Stack $CFStackName..."
    $stack = Get-CFNStack -StackName $CFStackName -Credential $credential -Region $CFRegion
}
catch {} #Do nothing as this will throw if the stack does not exist

if ($stack -ne $null) {
    if ($DeleteExistingStack -eq $false -and $UpdateExistingStack -eq $false) {
        Write-Output "Stack already exists. If you wish to automatically delete existing stacks, set 'Delete Existing Stack' to True. If you wish to automatically update existing stacks, set 'Update Existing Stack' to True."
        exit -1
    }

    if ($DeleteExistingStack -eq $true) {
        Write-Output "Stack found, deleting the existing Stack"

        Remove-CFNStack -Credential $credential -StackName $CFStackName -Region $AWSRegion -Force
        Confirm-CFNStackDeleted -credential $credential -stackName $CFStackName
    }
    else {
        Write-Output "Stack found, updating the existing Stack"
    }
}

if ($UseS3ForCloudFormationTemplate -eq $true) {

    if (-NOT $CloudFormationTemplateURI) { throw "You must enter a value for 'CloudFormation Template'." }

    if ($UseS3ForStackPolicy -eq $true) {
        Write-Output "Using CloudFormation Stack Policy from $CloudFormationStackPolicyURI"
        if ($stack -ne $null -and $UpdateExistingStack -eq $true) {
            Update-Stack -credential $credential
        }
        else {
            New-CFNStack -Credential $credential -OnFailure $CloudFormationOnFailure -TemplateUrl $CloudFormationTemplateURI -StackName $CFStackName -Region $CFRegion -Parameter $cloudFormationParams -Capability $CloudFormationCapability -StackPolicyURL $CloudFormationStackPolicyURI
        }
    }
    else {
        if ($stack -ne $null -and $UpdateExistingStack -eq $true) {
            Update-Stack -credential $credential
        }
        else {
            New-CFNStack -Credential $credential -OnFailure $CloudFormationOnFailure -TemplateUrl $CloudFormationTemplateURI -StackName $CFStackName -Region $CFRegion -Parameter $cloudFormationParams -Capability $CloudFormationCapability
        }
    }

    Confirm-CFNStackCompleted -credential $credential -stackName $CFStackName -region $CFRegion
}
else {
    Write-Output "Using CloudFormation script from Template"

    $validTemplate = Test-CFNTemplate -TemplateBody $CloudFormationTemplate -Region $CFRegion  -Credential $credential
    $statusCode = $validTemplate.HttpStatusCode.ToString()

    Write-Output "Validation Response: $statusCode"

    if ($validTemplate.HttpStatusCode) {
        if ($UseS3ForStackPolicy -eq $true) {
            Write-Output "Using CloudFormation Stack Policy from $CloudFormationStackPolicyURI"
            if ($stack -ne $null -and $UpdateExistingStack -eq $true) {
                Update-Stack -credential $credential
            }
            else {
                New-CFNStack -Credential $credential -OnFailure $CloudFormationOnFailure -TemplateBody $CloudFormationTemplate -StackName $CFStackName -Region $CFRegion -Parameter $cloudFormationParams -Capability $CloudFormationCapability -StackPolicyURL $CloudFormationStackPolicyURI
            }
        }
        else {
            if ($stack -ne $null -and $UpdateExistingStack -eq $true) {
                Update-Stack -credential $credential
            }
            else {
                New-CFNStack -Credential $credential -OnFailure $CloudFormationOnFailure -TemplateBody $CloudFormationTemplate -StackName $CFStackName -Region $CFRegion -Parameter $cloudFormationParams -Capability $CloudFormationCapability
            }
        }

        Confirm-CFNStackCompleted -credential $credential -stackName $CFStackName -region $CFRegion
    }
    else {
        throw "AWS CloudFormation template is not valid"
    }
}

$stack = Get-CFNStack -StackName $CFStackName -Credential $credential -Region $CFRegion