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
$AgentInstalled = If ($UsingWindowsSSH) { (-not -not (Get-Service ssh-agent -ErrorAction SilentlyContinue)) } else { Get-SshAgent }
If ($AgentInstalled) {
    $AgentRunning = If ($UsingWindowsSSH) { (Get-Service ssh-agent).Status -eq "Running" } else { Get-SshAgent }
    If (-not $AgentRunning) {
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
} else {
    Write-Warning "SSH Agent not found. Skipping ssh key load..."
}

# Docker
Import-Module posh-docker