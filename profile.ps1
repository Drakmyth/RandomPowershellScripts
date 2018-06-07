$IsAdministrator = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
If ($IsAdministrator) {
    Write-Host "Updating Help..."
    $_ = Start-Job { Update-Help }
}

function tail { Get-Content $args -Wait }

New-Alias which Get-Command

# Git
Import-Module posh-git

# SSH
$UsingWindowsSSH = $false
$AgentRunning = If ($UsingWindowsSSH) { Get-Service ssh-agent -ErrorAction SilentlyContinue } else { Get-SshAgent }
If (-Not $AgentRunning) {
    If ($UsingWindowsSSH) { Start-Service ssh-agent } else { Start-SshAgent }
}

$loadedKeys = Add-SshKey -l
ForEach ($item in Get-ChildItem ~/.ssh *.pub) {

    $privateKeyName = $item.BaseName
    if ($loadedKeys -match $privateKeyName) {
        # TODO: Why doesn't -not or -notmatch work here?
    } else {
        Add-SshKey ~/.ssh/$($privateKeyName)
    }
}

# Docker
Import-Module posh-docker