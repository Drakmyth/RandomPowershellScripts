function Set-UE4DefaultEnabledPlugins {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$False)]
        [String]$Path = $pwd,

        [Parameter(Mandatory=$False)]
        [String[]]$Plugins = @()
    )

    Begin {
        if ($PSVersionTable.PSVersion.Major -lt 6) {
            throw "Requires PowerShell 6.x or higher. Please update or complain to Epic that their *.uplugin files are invalid JSON."
        }

        $editorPath = [IO.Path]::Combine($Path,"Engine","Binaries","Win64","UE4Editor.exe")
        $editorPathFound = Test-Path -Path $editorPath -PathType Leaf
        if (-not $editorPathFound) {
            throw "Invalid engine path. Editor not found at `"$editorPath`"."
        }
        
        $pluginPath = [IO.Path]::Combine($Path,"Engine","Plugins")
        $pluginPathFound = Test-Path -Path $pluginPath
        if (-not $pluginPathFound) {
            throw "Plugin directory `"$pluginPath`" not found."
        }
    }
    
    Process {
        Write-Progress -Activity "Setting EnabledByDefault For Plugins" -CurrentOperation "Finding Plugins" -Status " " -PercentComplete 0
        $enginePlugins = Get-ChildItem -Path $pluginPath -Filter *.uplugin -File -Recurse
        $enabledPlugins = @()

        $i = 0
        $enginePlugins | ForEach-Object -Process {
            Write-Progress -Activity "Setting EnabledByDefault For Plugins" -CurrentOperation "Processing Plugins" -Status "Processing $($_.BaseName)" -PercentComplete ($i/$enginePlugins.Length*100)
            $content = Get-Content -Path $_.FullName -Raw
            $plugin = $content | ConvertFrom-Json
            
            $enableByDefault = $Plugins -contains $plugin.FriendlyName
            if ($enableByDefault) {
                Write-Verbose "Enabling $($_.BaseName)"
                $enabledPlugins += $plugin.FriendlyName
            } else {
                Write-Verbose "Disabling $($_.BaseName)"
            }

            Add-Member -InputObject $plugin -MemberType NoteProperty -Name "EnabledByDefault" -Value $enableByDefault -Force
            
            $content = $plugin | ConvertTo-Json -Depth 1024
            $content | Set-Content -Path $_.FullName

            $i++
            Write-Progress -Activity "Setting EnabledByDefault For Plugins" -CurrentOperation "Processing Plugins" -Status "$($_.BaseName) Processing Complete" -PercentComplete ($i/$enginePlugins.Length*100)
        }

        Write-Progress -Activity "Setting EnabledByDefault For Plugins" -Completed
    }

    End {
        Compare-Object -ReferenceObject $Plugins -DifferenceObject $enabledPlugins |
        Where-Object -Property SideIndicator -eq -Value "<=" |
        ForEach-Object -Process {
            Write-Error "Plugin `"$($_.InputObject)`" not found."
        }
    }
}

function Initialize-UE4RecommendedPlugins {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$False)]
        [String]$Path = $pwd
    )

    Begin {

    }

    Process {
        $pluginsToEnable = @("Content Browser - Asset Data Source",
                             "Content Browser - Class Data Source",
                             "Content Browser - File Data Source",
                             "Plugin Browser",
                             "Plugin Utilities",
                             "Visual Studio Integration")
        Set-UE4DefaultEnabledPlugins -Path $Path -Plugins $pluginsToEnable
    }

    End {

    }
}