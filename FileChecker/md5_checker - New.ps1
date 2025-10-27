# Function to generate or update MD5 checksum information
function New-MD5Hashes {
    [CmdletBinding()] # Enables -Verbose and other common parameters
    Param()

    $checksDir = "checks"
    $currentScriptFileName = $MyInvocation.MyCommand.Name
    $baseLocationPath = (Get-Location).Path
    $excludedFileNames = @("0")  # Exclude temp/status files like "0" to avoid false discrepancies

    # Create checks directory if it doesn't exist
    if (-not (Test-Path -LiteralPath $checksDir -PathType Container)) {
        Write-Host "Creating checksums directory: '$checksDir'" -ForegroundColor Yellow
        New-Item -Path $checksDir -ItemType Directory -Force | Out-Null
    }

    Write-Host "Scanning for files to process in '$baseLocationPath'..."
    $filesToProcess = Get-ChildItem -Path $baseLocationPath -File -Recurse -Force | Where-Object {
        $_.FullName -notlike "*$checksDir*" -and $_.Name -ne $currentScriptFileName -and $_.Name -notin $excludedFileNames
    }

    if ($filesToProcess.Count -eq 0) {
        Write-Host "No files found to process (excluding '$currentScriptFileName', items in '$checksDir', and excluded files)."
        return
    }

    Write-Host "Preparing to generate/update MD5 checksums for $($filesToProcess.Count) files..."
    $progressCounter = 0
    $totalFiles = $filesToProcess.Count
    
    # Counters for summary
    $processedFilesCount = 0    # Files successfully processed (hash generated and DB entry attempted)
    $pathsAddedToDbCount = 0      # Unique file paths newly added to infoData.RelativePaths
    $pathsUpdatedInDbCount = 0    # Unique file paths that had their LastSeen timestamp updated
    $pathsPrunedFromDbCount = 0   # Unique file paths removed from infoData.RelativePaths (missing on disk)
    $jsonFilesDeletedCount = 0    # Checksum JSON files deleted (empty after pruning)
    $errorCount = 0
    
    # To track unique JSON files touched, to correctly count new vs updated JSONs
    $jsonFilesAffectedThisRun = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $jsonFilesNewlyCreatedThisRun = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($fileItem in $filesToProcess) {
        $progressCounter++
        $percentComplete = if ($totalFiles -gt 0) { ($progressCounter / $totalFiles) * 100 } else { 0 }
        Write-Progress -Activity "Generating/Updating Checksums" -Status "Processing $($fileItem.Name)" -CurrentOperation "[$progressCounter/$totalFiles] - $($fileItem.FullName)" -PercentComplete $percentComplete

        try {
            # Basic validation of the file item
            if ($null -eq $fileItem -or $null -eq $fileItem.FullName -or $fileItem.FullName.Trim() -eq "") {
                Write-Warning "Skipping invalid file item (null or empty FullName) at index $progressCounter."
                $errorCount++
                continue
            }
            if (-not (Test-Path -LiteralPath $fileItem.FullName -PathType Leaf)) {
                Write-Warning "File not found or is a directory: '$($fileItem.FullName)'. Skipping."
                $errorCount++
                continue
            }

            $fileRelativePath = $fileItem.FullName.Substring($baseLocationPath.Length).TrimStart([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
            
            # Robust hash generation
            $hashObject = $null
            try {
                $hashObject = Get-FileHash -LiteralPath $fileItem.FullName -Algorithm MD5 -ErrorAction Stop
            } catch {
                Write-Warning "Error getting hash for '$($fileItem.FullName)': $($_.Exception.Message). Skipping."
                $errorCount++
                continue
            }

            if ($null -eq $hashObject -or $null -eq $hashObject.Hash -or $hashObject.Hash.Trim() -eq "") {
                Write-Warning "Get-FileHash returned invalid/empty hash for '$($fileItem.FullName)'. HashObject details: $($hashObject | Format-List | Out-String). Skipping."
                $errorCount++
                continue
            }
            $fileContentHash = $hashObject.Hash.ToLower()

            # CRITICAL CHECK: Ensure hash is a 32-char hex string (MD5 specific)
            # This is the main guard against creating files like "0.json" or ".json"
            if (-not ($fileContentHash -match '^[a-f0-9]{32}$')) {
                Write-Warning "Generated hash '$fileContentHash' for file '$($fileItem.FullName)' is not a valid 32-character hexadecimal MD5 format. Skipping."
                $errorCount++
                continue
            }

            $infoFilePath = Join-Path $checksDir ($fileContentHash + ".json")
            $currentTime = (Get-Date).ToUniversalTime().ToString("o") # ISO 8601 format

            $infoData = $null
            $jsonExistedBeforeAndValid = $false # Assume it's new or invalid initially

            if (Test-Path -LiteralPath $infoFilePath -PathType Leaf) {
                try {
                    $tempInfoData = Get-Content -LiteralPath $infoFilePath -Raw | ConvertFrom-Json
                    # Validate existing data: ContentMD5 must exist and match the filename hash
                    if ($null -ne $tempInfoData.ContentMD5 -and $tempInfoData.ContentMD5 -eq $fileContentHash) {
                        $infoData = $tempInfoData
                        $jsonExistedBeforeAndValid = $true
                        Write-Verbose "Loaded existing valid checksum file: '$infoFilePath'"
                    } else {
                        Write-Warning "Checksum file '$infoFilePath' has mismatched ContentMD5 ('$($tempInfoData.ContentMD5)') or is corrupted. It will be overwritten."
                        # $infoData remains $null, so it will be created fresh
                    }
                } catch {
                    Write-Warning "Could not read/parse existing info file '$infoFilePath'. It might be corrupted. Will attempt to overwrite. Error: $($_.Exception.Message)"
                    # $infoData remains $null, so it will be created fresh
                }
            }

            if ($null -eq $infoData) { # Create new infoData if it's null (new file, or existing was corrupt/mismatched)
                $infoData = @{
                    ContentMD5         = $fileContentHash
                    RelativePaths      = [System.Collections.ArrayList]::new() # Use ArrayList for easy .Add()
                    FirstCreated       = $currentTime # Timestamp for the content hash JSON file itself
                    LastContentUpdate  = $currentTime
                }
                if (-not $jsonExistedBeforeAndValid) { # Only count as new if it wasn't pre-existing and valid
                    [void]$jsonFilesNewlyCreatedThisRun.Add($infoFilePath)
                    Write-Verbose "Creating new checksum entry for '$fileContentHash' in '$infoFilePath'"
                } else {
                     Write-Verbose "Overwriting corrupted/mismatched checksum entry for '$fileContentHash' in '$infoFilePath'"
                }
            }
            [void]$jsonFilesAffectedThisRun.Add($infoFilePath) # Track all JSONs touched this run


            # Ensure RelativePaths is an ArrayList for modification
            if ($null -eq $infoData.RelativePaths) {
                $infoData.RelativePaths = [System.Collections.ArrayList]::new()
            } elseif (-not ($infoData.RelativePaths -is [System.Collections.ArrayList])) {
                $infoData.RelativePaths = [System.Collections.ArrayList]::new( ([System.Array]$infoData.RelativePaths) )
            }


            $pathObject = $infoData.RelativePaths | Where-Object { $_.Path -eq $fileRelativePath }
            if ($pathObject) {
                $pathObject.LastSeen = $currentTime
                $pathsUpdatedInDbCount++
                Write-Verbose "Updated LastSeen for path '$fileRelativePath' in '$infoFilePath'"
            } else {
                $newPathEntry = @{ Path = $fileRelativePath; FirstSeen = $currentTime; LastSeen = $currentTime }
                [void]$infoData.RelativePaths.Add($newPathEntry)
                $pathsAddedToDbCount++
                Write-Verbose "Added new path '$fileRelativePath' to '$infoFilePath'"
            }

            # Prune missing paths: Remove any RelativePaths that no longer exist on disk
            $pathsToRemove = @()
            foreach ($existingPathObj in $infoData.RelativePaths) {
                $fullExistingPath = Join-Path $baseLocationPath $existingPathObj.Path
                if (-not (Test-Path -LiteralPath $fullExistingPath -PathType Leaf)) {
                    $pathsToRemove += $existingPathObj
                }
            }
            foreach ($removePathObj in $pathsToRemove) {
                [void]$infoData.RelativePaths.Remove($removePathObj)
                $pathsPrunedFromDbCount++
                Write-Verbose "Pruned missing path '$($removePathObj.Path)' from '$infoFilePath'"
            }

            $infoData.LastContentUpdate = $currentTime # Update when content is confirmed or path list modified

            # If no paths remain after pruning, delete the JSON file
            if ($infoData.RelativePaths.Count -eq 0) {
                Write-Verbose "Deleting empty checksum file '$infoFilePath' as no paths remain for content '$fileContentHash'."
                Remove-Item -LiteralPath $infoFilePath -Force -ErrorAction SilentlyContinue
                [void]$jsonFilesAffectedThisRun.Remove($infoFilePath)
                if ($jsonFilesNewlyCreatedThisRun.Contains($infoFilePath)) {
                    [void]$jsonFilesNewlyCreatedThisRun.Remove($infoFilePath)
                }
                $jsonFilesDeletedCount++
                continue  # Skip saving the JSON since it's deleted
            }

            # Convert ArrayList back to a standard array for consistent JSON output (optional, ConvertTo-Json handles ArrayLists)
            if ($infoData.RelativePaths -is [System.Collections.ArrayList]) {
                $infoData.RelativePaths = $infoData.RelativePaths.ToArray()
            }

            $infoData | ConvertTo-Json -Depth 5 | Out-File -LiteralPath $infoFilePath -Encoding UTF8 -Force
            $processedFilesCount++
        }
        catch {
            Write-Warning "Unexpected error processing file '$($fileItem.FullName)': $($_.Exception.Message). StackTrace: $($_.ScriptStackTrace)"
            $errorCount++
        }
    }

    Write-Progress -Activity "Generating/Updating Checksums" -Completed

    $newJsonActualCount = $jsonFilesNewlyCreatedThisRun.Count
    $updatedJsonActualCount = $jsonFilesAffectedThisRun.Count - $newJsonActualCount

    Write-Host "`n----- Checksum Generation/Update Complete -----" -ForegroundColor Cyan
    Write-Host "Total files scanned from disk: $totalFiles"
    Write-Host "Successfully processed (checksum DB entry written/updated): $processedFilesCount"
    Write-Host "New checksum files created (for new content): $newJsonActualCount" -ForegroundColor Green
    Write-Host "Existing checksum files updated (content seen again or new path for existing content): $updatedJsonActualCount" -ForegroundColor Yellow
    Write-Host "New file paths added to checksum entries: $pathsAddedToDbCount"
    Write-Host "Existing file paths' 'LastSeen' timestamp updated: $pathsUpdatedInDbCount"
    Write-Host "Missing file paths pruned from checksum entries: $pathsPrunedFromDbCount" -ForegroundColor Magenta
    Write-Host "Empty checksum files deleted (no remaining paths): $jsonFilesDeletedCount" -ForegroundColor Red
    Write-Host "Errors encountered during processing: $errorCount" -ForegroundColor Red
    Write-Host "---------------------------------------------" -ForegroundColor Cyan
}

# Function to check MD5 hashes against stored .json files
function Test-MD5Hashes {
    $checksDir = "checks"
    $currentScriptFileName = $MyInvocation.MyCommand.Name
    $baseLocationPath = (Get-Location).Path
    $excludedFileNames = @("0")  # Exclude temp/status files like "0" to avoid false discrepancies

    if (-not (Test-Path -LiteralPath $checksDir -PathType Container)) {
        Write-Warning "The checksum directory '$checksDir' does not exist. Please generate checksums first."
        return
    }

    Write-Host "Verifying file integrity..."

    # 1. Index checksum database
    $checksumDB = @{} # Key: ContentMD5, Value: InfoData object
    $checksumFiles = Get-ChildItem -Path $checksDir -Filter "*.json" -File
    $dbFileCount = $checksumFiles.Count
    $progressCounterDBLoad = 0
    Write-Host "Phase 1/3: Loading checksum database from $dbFileCount files..."
    foreach ($checksumFileItem in $checksumFiles) {
        $progressCounterDBLoad++
        $percentCompleteDBLoad = if ($dbFileCount -gt 0) { ($progressCounterDBLoad / $dbFileCount) * 100 } else { 0 }
        Write-Progress -Activity "Loading Checksum DB" -Status "Processing $($checksumFileItem.Name)" -CurrentOperation "[$progressCounterDBLoad/$dbFileCount]" -PercentComplete $percentCompleteDBLoad
        try {
            $infoData = Get-Content -LiteralPath $checksumFileItem.FullName -Raw | ConvertFrom-Json
            if ($infoData.ContentMD5) {
                # Ensure ContentMD5 from file matches filename hash convention for extra safety
                $expectedHashFromFileName = $checksumFileItem.BaseName.ToLower()
                if ($infoData.ContentMD5.ToLower() -ne $expectedHashFromFileName) {
                    Write-Warning "Checksum file '$($checksumFileItem.FullName)' has internal ContentMD5 ('$($infoData.ContentMD5)') that mismatches its filename-derived hash ('$expectedHashFromFileName'). Skipping."
                    continue
                }
                $checksumDB[$infoData.ContentMD5] = $infoData
            } else {
                 Write-Warning "Skipping invalid checksum file: $($checksumFileItem.FullName) (missing ContentMD5)"
            }
        } catch {
            Write-Warning "Could not read or parse checksum file: $($checksumFileItem.FullName) - $($_.Exception.Message)"
        }
    }
    Write-Progress -Activity "Loading Checksum DB" -Completed

    if ($checksumDB.Count -eq 0) {
        Write-Host "No valid checksums found in '$checksDir'."
        return
    }

    # 2. Index files on disk
    $diskFiles = @{} # Key: RelativePath, Value: ContentMD5
    $filesToProcess = Get-ChildItem -Path $baseLocationPath -File -Recurse -Force | Where-Object {
        $_.FullName -notlike "*$checksDir*" -and $_.Name -ne $currentScriptFileName -and $_.Name -notin $excludedFileNames
    }

    if ($filesToProcess.Count -eq 0) {
        Write-Host "No files found on disk to verify (excluding script, checks directory, and excluded files)."
        return
    }
    
    $totalFilesOnDisk = $filesToProcess.Count
    Write-Host "Phase 2/3: Indexing $totalFilesOnDisk files on disk..."
    $progressCounterDiskIndex = 0
    $diskFileErrors = 0

    foreach ($fileItem in $filesToProcess) {
        $progressCounterDiskIndex++
        $percentCompleteDiskIndex = if ($totalFilesOnDisk -gt 0) { ($progressCounterDiskIndex / $totalFilesOnDisk) * 100 } else { 0 }
        Write-Progress -Activity "Indexing Disk Files" -Status "Hashing $($fileItem.Name)" -CurrentOperation "[$progressCounterDiskIndex/$totalFilesOnDisk]" -PercentComplete $percentCompleteDiskIndex
        try {
            # Validate file before hashing
            if (-not (Test-Path -LiteralPath $fileItem.FullName -PathType Leaf)) {
                Write-Warning "During disk indexing, file not found or is a directory: '$($fileItem.FullName)'. Skipping."
                $diskFileErrors++
                continue
            }
            $fileRelativePath = $fileItem.FullName.Substring($baseLocationPath.Length).TrimStart([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
            $hashValue = (Get-FileHash -LiteralPath $fileItem.FullName -Algorithm MD5 -ErrorAction Stop).Hash.ToLower()
            
            if (-not ($hashValue -match '^[a-f0-9]{32}$')) {
                Write-Warning "During disk indexing, generated hash '$hashValue' for file '$($fileItem.FullName)' is not a valid MD5 format. Skipping."
                $diskFileErrors++
                continue
            }
            $diskFiles[$fileRelativePath] = $hashValue
        } catch {
             Write-Warning "Could not hash disk file '$($fileItem.FullName)': $($_.Exception.Message)"
             $diskFileErrors++
        }
    }
    Write-Progress -Activity "Indexing Disk Files" -Completed
    Write-Host "Found $($diskFiles.Count) accessible files on disk to check against $($checksumDB.Count) unique content checksums in DB."
    if ($diskFileErrors -gt 0) {
        Write-Warning "$diskFileErrors errors occurred while indexing disk files."
    }


    # 3. Compare and Report
    $results = @{
        OK        = [System.Collections.ArrayList]::new()
        MODIFIED  = [System.Collections.ArrayList]::new() # Content changed at a known path
        MOVED     = [System.Collections.ArrayList]::new() # Known content, new path
        NEW       = [System.Collections.ArrayList]::new() # Unknown content
        DELETED   = [System.Collections.ArrayList]::new() # Known path for a content, but file no longer there
    }
    $processedDBPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    Write-Host "Phase 3/3: Comparing disk files against checksum database..."
    $diskFilesToCheckCount = $diskFiles.Keys.Count
    $progressCounterCompare = 0
    foreach ($diskRelPath in $diskFiles.Keys) {
        $progressCounterCompare++
        $percentCompleteCompare = if ($diskFilesToCheckCount -gt 0) { ($progressCounterCompare / $diskFilesToCheckCount) * 100 } else { 0 }
        Write-Progress -Activity "Verifying Files (Disk vs DB)" -Status "Checking disk file: $diskRelPath" -CurrentOperation "[$progressCounterCompare/$diskFilesToCheckCount]" -PercentComplete $percentCompleteCompare

        $diskContentHash = $diskFiles[$diskRelPath]
        if ($checksumDB.ContainsKey($diskContentHash)) {
            $infoData = $checksumDB[$diskContentHash]
            $pathEntry = $infoData.RelativePaths | Where-Object { $_.Path -eq $diskRelPath }
            if ($pathEntry) {
                [void]$results.OK.Add(@{ Path = $diskRelPath; ContentHash = $diskContentHash })
                [void]$processedDBPaths.Add("$($diskContentHash):$($diskRelPath)") # Suppress boolean output from .Add()
            } else {
                [void]$results.MOVED.Add(@{ Path = $diskRelPath; ContentHash = $diskContentHash; KnownOldPaths = $infoData.RelativePaths.Path })
            }
        } else {
            [void]$results.NEW.Add(@{ Path = $diskRelPath; ContentHash = $diskContentHash })
        }
    }
    Write-Progress -Activity "Verifying Files (Disk vs DB)" -Completed

    Write-Host "Phase 3/3: Checking checksum database for missing or altered files..."
    $dbPathsToCheckCount = 0
    $checksumDB.Values | ForEach-Object { if ($_.RelativePaths) {$dbPathsToCheckCount += $_.RelativePaths.Count} } # Make sure RelativePaths exists
    $progressCounterDBScan = 0

    foreach ($dbContentHash in $checksumDB.Keys) {
        $infoData = $checksumDB[$dbContentHash]
        if ($null -eq $infoData.RelativePaths) { continue } # Skip if no paths for this hash for some reason

        foreach ($dbPathEntry in $infoData.RelativePaths) {
            $progressCounterDBScan++
            $percentCompleteDBScan = if ($dbPathsToCheckCount -gt 0) { ($progressCounterDBScan / $dbPathsToCheckCount) * 100 } else { 0 }
            Write-Progress -Activity "Verifying Files (DB Scan)" -Status "Scanning DB entry: $($dbPathEntry.Path)" -CurrentOperation "[$progressCounterDBScan/$dbPathsToCheckCount]" -PercentComplete $percentCompleteDBScan

            $dbStoredPath = $dbPathEntry.Path
            if (-not $processedDBPaths.Contains("$($dbContentHash):$($dbStoredPath)")) {
                if ($diskFiles.ContainsKey($dbStoredPath)) {
                    [void]$results.MODIFIED.Add(@{ Path = $dbStoredPath; OriginalContentHash = $dbContentHash; CurrentContentHash = $diskFiles[$dbStoredPath] })
                } else {
                    [void]$results.DELETED.Add(@{ Path = $dbStoredPath; OriginalContentHash = $dbContentHash })
                }
            }
        }
    }
    Write-Progress -Activity "Verifying Files (DB Scan)" -Completed

    # Post-process for RENAMED: Detect hashes with both MOVED and DELETED, treat as RENAMED
    $results.RENAMED = [System.Collections.ArrayList]::new()
    $hashesWithMoved = @{}
    foreach ($movedItem in $results.MOVED.Clone()) {  # Clone to avoid modification during enumeration
        if (-not $hashesWithMoved.ContainsKey($movedItem.ContentHash)) {
            $hashesWithMoved[$movedItem.ContentHash] = [System.Collections.ArrayList]::new()
        }
        [void]$hashesWithMoved[$movedItem.ContentHash].Add($movedItem)
    }

    $hashesWithDeleted = @{}
    foreach ($deletedItem in $results.DELETED.Clone()) {  # Clone to avoid modification during enumeration
        if (-not $hashesWithDeleted.ContainsKey($deletedItem.OriginalContentHash)) {
            $hashesWithDeleted[$deletedItem.OriginalContentHash] = [System.Collections.ArrayList]::new()
        }
        [void]$hashesWithDeleted[$deletedItem.OriginalContentHash].Add($deletedItem)
    }

    foreach ($hash in $hashesWithMoved.Keys) {
        if ($hashesWithDeleted.ContainsKey($hash)) {
            # This hash has both MOVED and DELETED: Treat as RENAMED
            $movedItems = $hashesWithMoved[$hash]
            $deletedItems = $hashesWithDeleted[$hash]

            # Add to RENAMED (group all old/new paths for this hash)
            $renamedEntry = @{
                ContentHash = $hash
                OldPaths = $deletedItems | ForEach-Object { $_.Path }
                NewPaths = $movedItems | ForEach-Object { $_.Path }
            }
            [void]$results.RENAMED.Add($renamedEntry)

            # Remove from original MOVED and DELETED
            foreach ($movedItem in $movedItems) {
                [void]$results.MOVED.Remove($movedItem)
            }
            foreach ($deletedItem in $deletedItems) {
                [void]$results.DELETED.Remove($deletedItem)
            }
        }
    }

    # Output Results
    Write-Host "`n----- Verification Results -----" -ForegroundColor Cyan
    Write-Host "Total files on disk checked: $($diskFiles.Count)"
    Write-Host "Total unique content checksums in DB: $($checksumDB.Count)"
    
    $okCount = $results.OK.Count
    $modifiedCount = $results.MODIFIED.Count
    $movedCount = $results.MOVED.Count
    $newCount = $results.NEW.Count
    $deletedCount = $results.DELETED.Count
    $renamedCount = $results.RENAMED.Count

    if ($okCount -gt 0) {
        Write-Host "OK: $okCount" -ForegroundColor Green
        $results.OK | ForEach-Object { Write-Host "  - $($_.Path)" }
    }

    if ($modifiedCount -gt 0) {
        Write-Host "MODIFIED (content changed at a known location): $modifiedCount" -ForegroundColor Yellow
        $results.MODIFIED | ForEach-Object { Write-Host "  - $($_.Path) (Original content: $($_.OriginalContentHash), Current content: $($_.CurrentContentHash))" }
    }

    if ($renamedCount -gt 0) {
        Write-Host "RENAMED (known content at new location, with matching old location(s) removed): $renamedCount" -ForegroundColor Blue
        $results.RENAMED | ForEach-Object { 
            Write-Host "  - Content: $($_.ContentHash)"
            Write-Host "    Old path(s): $($_.OldPaths -join ', ')"
            Write-Host "    New path(s): $($_.NewPaths -join ', ')"
        }
        Write-Host "  (Run 'New-MD5Hashes' to update known locations for renamed files)" -ForegroundColor DarkGray
    }

    if ($movedCount -gt 0) {
        Write-Host "MOVED (known content found at a new/unexpected location, without a matching deletion): $movedCount" -ForegroundColor Blue
        $results.MOVED | ForEach-Object { Write-Host "  - $($_.Path) (Content: $($_.ContentHash), Was previously at: ($($_.KnownOldPaths -join ', ')))" }
        Write-Host "  (Run 'New-MD5Hashes' to update known locations for moved files)" -ForegroundColor DarkGray
    }
    if ($newCount -gt 0) {
        Write-Host "NEW (unknown content): $newCount" -ForegroundColor Magenta
        $results.NEW | ForEach-Object { Write-Host "  - $($_.Path) (Content: $($_.ContentHash))" }
        Write-Host "  (Run 'New-MD5Hashes' to add new files)" -ForegroundColor DarkGray
    }
    if ($deletedCount -gt 0) {
        Write-Host "DELETED (file no longer at a previously known location for its content, without a matching move/rename): $deletedCount" -ForegroundColor Red
        $results.DELETED | ForEach-Object { Write-Host "  - $($_.Path) (Expected content: $($_.OriginalContentHash))" }
    }
    
    # Always show all categories in summary, even if count is 0, for consistency
    Write-Host "`n----- Summary of Discrepancies -----" -ForegroundColor Cyan
    Write-Host "OK: $okCount" -ForegroundColor Green
    Write-Host "MODIFIED: $modifiedCount" -ForegroundColor Yellow
    Write-Host "RENAMED: $renamedCount" -ForegroundColor Blue
    Write-Host "MOVED: $movedCount" -ForegroundColor Blue
    Write-Host "NEW: $newCount" -ForegroundColor Magenta
    Write-Host "DELETED: $deletedCount" -ForegroundColor Red
    Write-Host "------------------------------------" -ForegroundColor Cyan

    if ($modifiedCount + $movedCount + $newCount + $deletedCount + $renamedCount -eq 0) {
        Write-Host "All files are verified and match the checksum database." -ForegroundColor Green
    } else {
        Write-Host "Some discrepancies were found. Review the details above." -ForegroundColor Yellow
        if ($movedCount + $newCount + $renamedCount > 0) {
             Write-Host "Consider running 'New-MD5Hashes' to update the database with new/moved/renamed files." -ForegroundColor DarkCyan
        }
    }
}


# --- Main CLI Menu ---
function Show-Menu {
    Write-Host "--------------------------------"
    Write-Host "        MD5 Hash Checker        "
    Write-Host "      (Content-Addressable)     "
    Write-Host "--------------------------------"
    Write-Host "1. Generate/Update Checksums"
    Write-Host "2. Verify File Integrity"
    Write-Host "3. Exit"
    Write-Host "--------------------------------"
    Write-Host -NoNewLine "Choose an option: "
}

# Set $VerbosePreference to "Continue" to see Write-Verbose messages
# $VerbosePreference = "SilentlyContinue" # Default
# $VerbosePreference = "Continue" 

while ($true) {
    Show-Menu
    $choice = Read-Host

    switch ($choice) {
        1 {
            New-MD5Hashes # If you want verbose output for this: New-MD5Hashes -Verbose
            Write-Host "`nPress Enter to return to the menu..."
            Read-Host | Out-Null
        }
        2 {
            Test-MD5Hashes
            Write-Host "`nPress Enter to return to the menu..."
            Read-Host | Out-Null
        }
        3 {
            Write-Host "Exiting the script."
            exit
        }
        default {
            Write-Host "Invalid option, please try again." -ForegroundColor Yellow
        }
    }
    if ($Host.Name -eq "ConsoleHost") { Clear-Host } # Clear host only if in console
}