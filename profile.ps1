$IsAdministrator = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
If ($IsAdministrator) {
    Write-Host "Updating Help..."
    $_ = Start-Job { Update-Help }
}

function tail { Get-Content $args -Wait }

# Git
Import-Module posh-git

$UsingWindowsSSH = $false
$AgentRunning = If ($UsingWindowsSSH) { Get-Service ssh-agent -ErrorAction SilentlyContinue } else { Get-SshAgent }
If (-Not $AgentRunning) {
    If ($UsingWindowsSSH) { Start-Service ssh-agent } else { Start-SshAgent }

    ForEach ($item in Get-ChildItem ~/.ssh *.pub) {
        Add-SshKey ~/.ssh/$($item.BaseName)
    }
}

# Docker
Import-Module posh-docker