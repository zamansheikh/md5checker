# FileChecker.ps1

# Function to generate checksum
function Generate-Checksum {
    param (
        [string]$Directory
    )

    $excludedFiles = @("checksums.txt", "temp_checksums.txt", "mismatch_log.txt", "moved_files_log.txt", "FileChecker.ps1")
    $hashes = @()
    
    $files = Get-ChildItem -Recurse -File -Path $Directory
    $totalFiles = $files.Count
    $progressCounter = 0

    Write-Progress -Activity "Generating Checksums" -Status "Processing 0/$totalFiles" -PercentComplete 0

    foreach ($file in $files) {
        if ($excludedFiles -notcontains $file.Name) {
            $hash = Get-FileHash -Path $file.FullName -Algorithm SHA256
            $hashes += "$($file.FullName) $($hash.Hash)"

            $progressCounter++
            $percentComplete = [math]::Round(($progressCounter / $totalFiles) * 100)
            Write-Progress -Activity "Generating Checksums" -Status "Processing $progressCounter/$totalFiles" -PercentComplete $percentComplete
        }
    }

    $hashes | Out-File -FilePath (Join-Path $Directory "checksums.txt")
    Write-Host "Checksum generated and saved to checksums.txt"
}

# Function to match checksum
function Match-Checksum {
    param (
        [string]$Directory
    )

    $checksumFilePath = (Join-Path $Directory "checksums.txt")

    if (-Not (Test-Path $checksumFilePath)) {
        Write-Host "checksums.txt not found. Please generate checksums first."
        return
    }

    $originalHashes = Get-Content -Path $checksumFilePath
    $excludedFiles = @("checksums.txt", "temp_checksums.txt", "mismatch_log.txt", "moved_files_log.txt", "FileChecker.ps1")
    $tempHashes = @()
    $mismatchLog = @()

    $files = Get-ChildItem -Recurse -File -Path $Directory
    $totalFiles = $files.Count
    $progressCounter = 0

    Write-Progress -Activity "Matching Checksums" -Status "Matching 0/$totalFiles" -PercentComplete 0

    foreach ($file in $files) {
        if ($excludedFiles -notcontains $file.Name) {
            $hash = Get-FileHash -Path $file.FullName -Algorithm SHA256
            $tempHashes += "$($file.FullName) $($hash.Hash)"

            $progressCounter++
            $percentComplete = [math]::Round(($progressCounter / $totalFiles) * 100)
            Write-Progress -Activity "Matching Checksums" -Status "Matching $progressCounter/$totalFiles" -PercentComplete $percentComplete
        }
    }

    $tempHashes | Out-File -FilePath (Join-Path $Directory "temp_checksums.txt")

    # Create hash maps for quick lookup
    $originalHashMap = @{}
    $originalHashes | ForEach-Object { 
        $split = $_.Split(" ", 2)
        if ($split.Count -eq 2) {
            $originalHashMap[$split[1].Trim()] = $split[0].Trim()
        }
    }

    $tempHashMap = @{}
    $tempHashes | ForEach-Object { 
        $split = $_.Split(" ", 2)
        if ($split.Count -eq 2) {
            $tempHashMap[$split[1].Trim()] = $split[0].Trim()
        }
    }

    # Initial pass: Identify mismatches and log them
    foreach ($originalHash in $originalHashes) {
        $split = $originalHash.Split(" ", 2)
        if ($split.Count -eq 2) {
            $originalPath = $split[0].Trim()
            $originalHashValue = $split[1].Trim()

            if (-not [string]::IsNullOrEmpty($originalHashValue) -and -not $tempHashMap.ContainsKey($originalHashValue)) {
                $mismatchLog += "File missing: '$originalPath' (hash: $originalHashValue)"
            }
        }
    }

    foreach ($tempHash in $tempHashes) {
        $split = $tempHash.Split(" ", 2)
        if ($split.Count -eq 2) {
            $tempPath = $split[0].Trim()
            $tempHashValue = $split[1].Trim()

            if (-not [string]::IsNullOrEmpty($tempHashValue) -and -not $originalHashMap.ContainsKey($tempHashValue)) {
                $mismatchLog += "New or changed file: '$tempPath' (hash: $tempHashValue)"
            }
        }
    }

    # Output results
    if ($mismatchLog.Count -eq 0) {
        Write-Host "All files match."
    } else {
        $mismatchLog | Out-File -FilePath (Join-Path $Directory "mismatch_log.txt")
        Write-Host "Mismatch log saved to mismatch_log.txt"
    }

    Remove-Item (Join-Path $Directory "temp_checksums.txt") -ErrorAction SilentlyContinue
}

# Main menu
function Main {
    while ($true) {
        Write-Host "Select an option:"
        Write-Host "1. Generate checksum"
        Write-Host "2. Match checksum"
        Write-Host "3. Exit"
        $choice = Read-Host "Enter your choice"

        switch ($choice) {
            1 {
                $directory = Get-Location
                Generate-Checksum -Directory $directory
            }
            2 {
                $directory = Get-Location
                Match-Checksum -Directory $directory
            }
            3 {
                Write-Host "Exiting..."
                exit
            }
            default {
                Write-Host "Invalid option. Please select 1, 2, or 3."
            }
        }
    }
}

# Run the main menu
Main
