<#
    .Synopsis
        Downloads a soundtrack from KHInsider
    .Description
        Parses an album for download links of individual songs on downloads.khinsider.com and downloads them to the specified directory
    .Parameter Destination
        The target directory to download the songs into (e.g. "C:\Users\shaun_000\Desktop\temp\")
    .Parameter AlbumUri
        The full link to the album page (e.g. "https://downloads.khinsider.com/game-soundtracks/album/link-s-awakening-dx")
#>

function Download-Album{
    [CmdletBinding()]
    param([Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=0)]
          [ValidateScript({ if (Test-Path $_) { $true } else { throw "$_ does not exist." }})]
          [string]$Destination,
          [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=1)]
          [ValidateScript({ if ($_ -like "https://downloads.khinsider.com/game-soundtracks/album/*") { $true } else { throw "$_ is not a valid album URI." }})]
          [string]$AlbumUri
          )
    process {
        function GetDetailUris([string] $albumUri) {
            Write-Host $albumUri
            $HttpContent = Invoke-WebRequest -URI $albumUri
            return ($HttpContent.Links | Where-Object {$_.innerText -eq "Download"}).href
        }

        function GetFileDownloadUri([string] $detailUri) {
            $HttpContent = Invoke-WebRequest -URI $detailUri
            return ($HttpContent.Links | Where-Object {$_.innerText -eq "Click here to download"}).href
        }

        $wc = New-Object System.Net.WebClient

        $detailUris = GetDetailUris($AlbumUri)
        foreach($detailUri in $detailUris) {
            $Destination = resolve-path $Destination

            if ($Destination -notlike "*\") {
                $Destination += "\"
            }

            $targetFile = $Destination + [io.path]::GetFileName($detailUri)
            $downloadUri = GetFileDownloadUri $detailUri

            "Downloading file: " + $downloadUri

            Write-Host $downloadUri
            Write-Host $targetFile
            $wc.DownloadFile($downloadUri, $targetFile)
        }

        "Album Download Complete"
    }
}