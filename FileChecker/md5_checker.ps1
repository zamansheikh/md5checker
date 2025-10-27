# Function to generate MD5 hashes for each file and save them in the checks\ directory
function New-MD5Hashes {
    $checksDir = "checks"
    $currentScript = "md5_checker.ps1"  # Explicitly set the current script name to exclude

    # Create checks directory if it doesn't exist
    if (-not (Test-Path -Path $checksDir -PathType Container)) {
        New-Item -Path $checksDir -ItemType Directory -Force
    }

    # Get all files, excluding the current script and anything in the checks directory
    $files = Get-ChildItem -Path $(Get-Location) -File -Recurse -Force | Where-Object {
        $_.FullName -notlike "*$checksDir*" -and $_.Name -ne $currentScript
    }
    Write-Host "Generating MD5 checksums for: $($files.Count) files (including hidden files) in $(Get-Location)..."
    $counter = 1
    $totalFiles = $files.Count
    $okFiles = 0
    $faildFiles = 0
    $failedFilesList = @()

    # Get all files (including hidden files), excluding the current script and anything in the checks directory
    Get-ChildItem -Path $(Get-Location) -File -Recurse -Force | Where-Object {
        $_.FullName -notlike "*$checksDir*" -and $_.Name -ne $currentScript
    } | ForEach-Object {
        #bool variable to check ok or not
        $ok = $true
        $file = $_
        # Inplement a try-catch block to handle any errors that may occur during the process
        try {
            # Calculate the MD5 checksum for the current file
            $checksum = Get-FileHash -Path $file.FullName -Algorithm MD5 | Select-Object Hash
            # Store checksum in a .checks file inside the checks directory, retaining the original extension
            $outputFile = Join-Path $checksDir -ChildPath ($file.Name + ".checks")
            $checksum.Hash | Out-File -FilePath $outputFile
        }
        catch {
            $ok = $false
            $failedFilesList += $file.FullName
            Write-Warning "Error generating checksum ! Please fix the file name - to cancel the operation, press Ctrl+C."
        }
        #Write a if condition to check if the file is ok or not
        if ($ok) {
            # Display progress
            Write-Host "[$counter/$($files.Count)] :$($file.FullName) : CHECKS CREATED."
            $counter++
            $okFiles++
        }
        else {
            # Display progress
            Write-Host "[$counter/$($files.Count)] :$($file.FullName) : FAILED."
            $counter++
            $faildFiles++
        }
        
    }
    # Print result summary
    if ($faildFiles -eq 0) {
        Write-Host "All files have been processed successfully.Checksums have been generated for all files."
    }
    else {
        Write-Host "CHECKS CREATED: $okFiles out of $totalFiles files, $faildFiles are FAILED to Create CHECKS."
        Write-Host "Files that failed to generate checksums:"
        $failedFilesList | ForEach-Object {
            Write-Host $_
        }
    }

    Write-Host "MD5 checksums saved in $checksDir"
}

# Function to check MD5 hashes against stored .checks files
function Test-MD5Hashes {
    $checksDir = "checks"
    $currentScript = "md5_checker.ps1"  # Explicitly set the current script name to exclude

    # Get all files, excluding the current script and anything in the checks directory
    $files = Get-ChildItem -Path $(Get-Location) -File -Recurse -Force | Where-Object {
        $_.FullName -notlike "*$checksDir*" -and $_.Name -ne $currentScript
    }
    $counter = 1
    if (-not (Test-Path -Path $checksDir -PathType Container)) {
        Write-Warning "The directory '$checksDir' does not exist. Please generate checksums first."
        return
    }

    Write-Host "Checking $($files.Count) files integrity (including hidden files) by comparing checksums in $checksDir..."

    $totalFiles = 0
    $matchedFiles = 0
    $unmatchedFiles = 0
    $unmatchedList = @()

    # Get all files (including hidden files), excluding the current script and anything in the checks directory
    Get-ChildItem -Path $(Get-Location) -File -Recurse -Force | Where-Object {
        $_.FullName -notlike "*$checksDir*" -and $_.Name -ne $currentScript
    } | ForEach-Object {
        $file = $_
        $totalFiles++
        $filename = $file.Name  # Retain the file extension for matching
        $checksFile = Join-Path $checksDir -ChildPath ($filename + ".checks")

        # Check if .checks file exists
        if (Test-Path -Path $checksFile -PathType Leaf) {
            # Read the entire content of the .checks file
            $storedChecksum = Get-Content -Path $checksFile

            # Convert checksums to lowercase for consistent comparison
            $storedChecksum = $storedChecksum.ToLower()

            # Calculate the current checksum
            $currentChecksum = Get-FileHash -Path $file.FullName -Algorithm MD5 | Select-Object Hash
            $currentChecksumHash = $currentChecksum.Hash.ToLower()

            # Compare the checksums
            if ($storedChecksum -eq $currentChecksumHash) {
                Write-Host "[$counter/$($files.Count)]: ${file}: OK"
                $matchedFiles++
                $counter++
            }
            else {
                Write-Host "[$counter/$($files.Count)]: ${file}: FAILED"
                $unmatchedFiles++
                $unmatchedList += $file.FullName
                $counter++
            }
        }
        else {
            Write-Warning "Warning: Checksum file for '${file}' not found in '$checksDir'."
            $unmatchedFiles++
            $unmatchedList += $file.FullName
        }
    }

    # Print result summary
    if ($unmatchedFiles -eq 0) {
        Write-Host "All files match."
    }
    else {
        Write-Host "Match: $matchedFiles out of $totalFiles files, $unmatchedFiles not matched."
        Write-Host "Files that didn't match or had no checksum file:"
        $unmatchedList | ForEach-Object {
            Write-Host $_
        }
    }
}

# CLI Menu
function Show-Menu {
    Write-Host "--------------------------------"
    Write-Host "       MD5 Hash Checker          "
    Write-Host "--------------------------------"
    Write-Host "1. Start MD5 Check (Generate .checks files)"
    Write-Host "2. Match MD5 Hashes (Test against .checks files)"
    Write-Host "3. Exit"
    Write-Host "--------------------------------"
    Write-Host -NoNewLine "Choose an option: "
}

# Main loop
while ($true) {
    Show-Menu
    $choice = Read-Host

    switch ($choice) {
        1 {
            New-MD5Hashes
            break
        }
        2 {
            Test-MD5Hashes
            break
        }
        3 {
            Write-Host "Exiting the script."
            exit
        }
        default {
            Write-Host "Invalid option, please try again."
        }
    }
}
