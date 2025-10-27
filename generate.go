package main

import (
	"compress/gzip"
	"crypto/md5"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"
)

type PathEntry struct {
	Path      string `json:"Path"`
	FirstSeen string `json:"FirstSeen"`
	LastSeen  string `json:"LastSeen"`
}

type InfoData struct {
	ContentMD5        string      `json:"ContentMD5"`
	RelativePaths     []PathEntry `json:"RelativePaths"`
	FirstCreated      string      `json:"FirstCreated"`
	LastContentUpdate string      `json:"LastContentUpdate"`
}

func NewMD5Hashes(regenerateAll bool) {
	baseLocationPath, _ := os.Getwd()
	checksumFileName := "checksums.json.gz"
	excludedFileNames := []string{"0", checksumFileName}

	// Exclude all md5checker binaries (current exe and all platform builds)
	excludedPrefixes := []string{"md5checker"}

	if regenerateAll {
		fmt.Println("╔════════════════════════════════════════════════════════════════╗")
		fmt.Println("║           REGENERATING ALL CHECKSUMS (FULL SCAN)               ║")
		fmt.Println("╚════════════════════════════════════════════════════════════════╝")
	} else {
		fmt.Println("╔════════════════════════════════════════════════════════════════╗")
		fmt.Println("║              ADDING NEW FILES TO DATABASE                      ║")
		fmt.Println("╚════════════════════════════════════════════════════════════════╝")
	}

	fmt.Printf("Scanning for files to process in '%s'...\n", baseLocationPath)
	var filesToProcess []string
	filepath.WalkDir(baseLocationPath, func(path string, d os.DirEntry, err error) error {
		if err != nil {
			return nil
		}
		if d.IsDir() {
			return nil
		}
		// Skip exact matches
		if contains(excludedFileNames, d.Name()) {
			return nil
		}
		// Skip files starting with excluded prefixes
		for _, prefix := range excludedPrefixes {
			if strings.HasPrefix(d.Name(), prefix) {
				return nil
			}
		}
		filesToProcess = append(filesToProcess, path)
		return nil
	})

	if len(filesToProcess) == 0 {
		fmt.Println("No files found to process (excluding checks directory and excluded files).")
		return
	}

	fmt.Printf("Found %d files to process...\n", len(filesToProcess))

	// Load existing checksum database
	checksumDB := make(map[string]InfoData)
	checksumFilePath := filepath.Join(baseLocationPath, checksumFileName)
	f, err := os.Open(checksumFilePath)
	if err == nil {
		defer f.Close()
		gz, gzErr := gzip.NewReader(f)
		if gzErr == nil {
			defer gz.Close()
			decoder := json.NewDecoder(gz)
			if decodeErr := decoder.Decode(&checksumDB); decodeErr != nil {
				fmt.Printf("Warning: Could not parse existing checksum file: %v. Starting fresh.\n", decodeErr)
				checksumDB = make(map[string]InfoData)
			}
		}
	}

	processedFilesCount := 0
	pathsAddedToDbCount := 0
	pathsUpdatedInDbCount := 0
	pathsPrunedFromDbCount := 0
	errorCount := 0

	md5Pattern := regexp.MustCompile("^[a-f0-9]{32}$")

	for _, filePath := range filesToProcess {
		fileRelativePath, _ := filepath.Rel(baseLocationPath, filePath)

		// Compute hash
		file, err := os.Open(filePath)
		if err != nil {
			fmt.Printf("Error opening file '%s': %v\n", filePath, err)
			errorCount++
			continue
		}
		defer file.Close()

		hash := md5.New()
		if _, err := io.Copy(hash, file); err != nil {
			fmt.Printf("Error hashing file '%s': %v\n", filePath, err)
			errorCount++
			continue
		}
		fileContentHash := fmt.Sprintf("%x", hash.Sum(nil))

		if !md5Pattern.MatchString(fileContentHash) {
			fmt.Printf("Generated hash '%s' for file '%s' is not a valid MD5 format. Skipping.\n", fileContentHash, filePath)
			errorCount++
			continue
		}

		currentTime := time.Now().UTC().Format(time.RFC3339)

		// Check if this file path already exists in ANY hash entry
		existingHash := ""
		for hash, info := range checksumDB {
			for _, p := range info.RelativePaths {
				if p.Path == fileRelativePath {
					existingHash = hash
					break
				}
			}
			if existingHash != "" {
				break
			}
		}

		// If regenerateAll is false and file already exists in DB, skip it
		if !regenerateAll && existingHash != "" {
			if existingHash == fileContentHash {
				// File hasn't changed, just update LastSeen
				for i := range checksumDB[existingHash].RelativePaths {
					if checksumDB[existingHash].RelativePaths[i].Path == fileRelativePath {
						checksumDB[existingHash].RelativePaths[i].LastSeen = currentTime
						pathsUpdatedInDbCount++
						break
					}
				}
			}
			// Skip processing - don't update if content changed
			continue
		}

		// If regenerateAll is true and file exists with different hash, remove old entry
		if regenerateAll && existingHash != "" && existingHash != fileContentHash {
			// Remove from old hash entry
			oldInfo := checksumDB[existingHash]
			var newPaths []PathEntry
			for _, p := range oldInfo.RelativePaths {
				if p.Path != fileRelativePath {
					newPaths = append(newPaths, p)
				}
			}
			if len(newPaths) == 0 {
				delete(checksumDB, existingHash)
			} else {
				oldInfo.RelativePaths = newPaths
				checksumDB[existingHash] = oldInfo
			}
		}

		infoData, exists := checksumDB[fileContentHash]
		if !exists {
			infoData = InfoData{
				ContentMD5:        fileContentHash,
				RelativePaths:     []PathEntry{},
				FirstCreated:      currentTime,
				LastContentUpdate: currentTime,
			}
		}

		pathEntry := findPathEntry(infoData.RelativePaths, fileRelativePath)
		if pathEntry != nil {
			pathEntry.LastSeen = currentTime
			pathsUpdatedInDbCount++
		} else {
			newEntry := PathEntry{
				Path:      fileRelativePath,
				FirstSeen: currentTime,
				LastSeen:  currentTime,
			}
			infoData.RelativePaths = append(infoData.RelativePaths, newEntry)
			pathsAddedToDbCount++
		}

		infoData.LastContentUpdate = currentTime
		checksumDB[fileContentHash] = infoData
		processedFilesCount++
	}

	// Prune missing paths across all entries
	for hash, infoData := range checksumDB {
		var newPaths []PathEntry
		for _, p := range infoData.RelativePaths {
			fullPath := filepath.Join(baseLocationPath, p.Path)
			if _, err := os.Stat(fullPath); err == nil {
				newPaths = append(newPaths, p)
			} else {
				pathsPrunedFromDbCount++
			}
		}
		if len(newPaths) == 0 {
			delete(checksumDB, hash)
		} else {
			infoData.RelativePaths = newPaths
			checksumDB[hash] = infoData
		}
	}

	// Save the database (compressed)
	checksumFilePath = filepath.Join(baseLocationPath, checksumFileName)
	file, createErr := os.Create(checksumFilePath)
	if createErr != nil {
		fmt.Printf("Error creating checksum file: %v\n", createErr)
		return
	}
	defer file.Close()
	gz := gzip.NewWriter(file)
	defer gz.Close()
	encoder := json.NewEncoder(gz)
	if encodeErr := encoder.Encode(checksumDB); encodeErr != nil {
		fmt.Printf("Error encoding checksum database: %v\n", encodeErr)
		return
	}

	fmt.Println("\n╔════════════════════════════════════════════════════════════════╗")
	if regenerateAll {
		fmt.Println("║         CHECKSUM REGENERATION COMPLETE                         ║")
	} else {
		fmt.Println("║         NEW FILES ADDED TO DATABASE                            ║")
	}
	fmt.Println("╚════════════════════════════════════════════════════════════════╝")
	fmt.Printf("  Total files scanned: %d\n", len(filesToProcess))
	fmt.Printf("  Successfully processed: %d\n", processedFilesCount)
	if regenerateAll {
		fmt.Printf("  Checksums regenerated: %d\n", processedFilesCount)
	} else {
		fmt.Printf("  New file paths added: %d\n", pathsAddedToDbCount)
		fmt.Printf("  Existing paths updated: %d\n", pathsUpdatedInDbCount)
	}
	fmt.Printf("  Missing paths pruned: %d\n", pathsPrunedFromDbCount)
	if errorCount > 0 {
		fmt.Printf("  Errors encountered: %d\n", errorCount)
	}
	fmt.Println("────────────────────────────────────────────────────────────────")
	fmt.Printf("✓ Database saved to: %s\n", checksumFilePath)
	fmt.Println("════════════════════════════════════════════════════════════════")
}

func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}

func findPathEntry(paths []PathEntry, path string) *PathEntry {
	for i := range paths {
		if paths[i].Path == path {
			return &paths[i]
		}
	}
	return nil
}
