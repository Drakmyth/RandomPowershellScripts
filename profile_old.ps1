# This is an older profile I used before windows had native OpenSSH support.
# It's largely redundant now, but am keeping it around until the native implementation has been put through its paces

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
function Start-SshWindowsAgent {
    $Agent = Get-Service ssh-agent -ErrorAction SilentlyContinue
    If (-not $Agent) { return "Windows SSH Agent Service not found." }
    If ($Agent.StartType -eq "Disabled") { return "Windows SSH Agent Service found but Disabled." }

    If ($Agent.Status -ne "Running") {
        Start-Service ssh-agent
    }
}

function Start-SshPoshAgent {
    $Agent = Get-SshAgent
    If (-not $Agent) {
        Start-SshAgent
    }
}

function Start-Ssh {
    
    $UsingWindowsSSH = $false
    If ($UsingWindowsSSH) {
        $SshStartedError = Start-SshWindowsAgent
    } else {
        $SshStartedError = Start-SshPoshAgent
    }

    If ($SshStartedError) {
        Write-Warning "SSH Agent not found or problem starting agent: $($SshStartedError) Skipping ssh key load..."
        return
    } else {
        $loadedKeys = Add-SshKey -l
        ForEach ($item in Get-ChildItem ~/.ssh *.pub) {
            
            $privateKeyName = $item.BaseName
            if ($loadedKeys -match $privateKeyName) {
                # TODO: Why doesn't -not or -notmatch work here?
            } else {
                Add-SshKey ~/.ssh/$($privateKeyName)
            }
        }
    }
}

Start-Ssh

# Docker
Import-Module posh-docker
