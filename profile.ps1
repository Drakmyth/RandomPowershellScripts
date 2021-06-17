#$host.ui.RawUI.WindowTitle = "Windows PowerShell"

$IsAdministrator = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
If ($IsAdministrator) {
    Write-Host "Updating Help..."
    $_ = Start-Job { Update-Help }
}

function tail { Get-Content $args -Wait }

New-Alias which Get-Command

# Git
Import-Module posh-git

# Docker
Import-Module DockerCompletion
