package main

import (
	"compress/gzip"
	"crypto/md5"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
)

type Result struct {
	Path                string
	ContentHash         string
	OriginalContentHash string
	KnownOldPaths       []string
	OldPaths            []string
	NewPaths            []string
}

func TestMD5Hashes() {
	baseLocationPath, _ := os.Getwd()
	checksumFileName := "checksums.json.gz"
	excludedFileNames := []string{"0", "md5checker.exe", checksumFileName}
	excludedPrefixes := []string{"md5checker"}

	checksumFilePath := filepath.Join(baseLocationPath, checksumFileName)
	if _, err := os.Stat(checksumFilePath); os.IsNotExist(err) {
		fmt.Printf("The checksum file '%s' does not exist. Please generate checksums first.\n", checksumFilePath)
		return
	}

	fmt.Println("Verifying file integrity...")

	// Load checksum DB
	checksumDB := make(map[string]InfoData)
	f, err := os.Open(checksumFilePath)
	if err != nil {
		fmt.Printf("Could not open checksum database file '%s': %v\n", checksumFilePath, err)
		return
	}
	defer f.Close()
	gz, err := gzip.NewReader(f)
	if err != nil {
		fmt.Printf("Could not create gzip reader: %v\n", err)
		return
	}
	defer gz.Close()
	decoder := json.NewDecoder(gz)
	if err := decoder.Decode(&checksumDB); err != nil {
		fmt.Printf("Could not parse checksum database: %v\n", err)
		return
	}

	if len(checksumDB) == 0 {
		fmt.Println("No valid checksums found in database.")
		return
	}

	// Index files on disk
	diskFiles := make(map[string]string)
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

	for _, filePath := range filesToProcess {
		file, err := os.Open(filePath)
		if err != nil {
			continue
		}
		defer file.Close()

		hash := md5.New()
		io.Copy(hash, file)
		fileContentHash := fmt.Sprintf("%x", hash.Sum(nil))

		fileRelativePath, _ := filepath.Rel(baseLocationPath, filePath)
		diskFiles[fileRelativePath] = fileContentHash
	}

	results := map[string][]Result{
		"OK":       {},
		"MODIFIED": {},
		"MOVED":    {},
		"NEW":      {},
		"DELETED":  {},
		"RENAMED":  {},
	}

	processedDBPaths := make(map[string]bool)
	processedDiskPaths := make(map[string]bool)

	// Compare disk to DB
	for relPath, diskHash := range diskFiles {
		if infoData, exists := checksumDB[diskHash]; exists {
			found := false
			for _, p := range infoData.RelativePaths {
				if p.Path == relPath {
					results["OK"] = append(results["OK"], Result{Path: relPath, ContentHash: diskHash})
					processedDBPaths[diskHash+":"+relPath] = true
					processedDiskPaths[relPath] = true
					found = true
					break
				}
			}
			if !found {
				results["MOVED"] = append(results["MOVED"], Result{Path: relPath, ContentHash: diskHash, KnownOldPaths: getPaths(infoData.RelativePaths)})
				processedDiskPaths[relPath] = true
			}
		}
	}

	// Check DB for missing or modified
	for hash, infoData := range checksumDB {
		for _, dbPath := range infoData.RelativePaths {
			key := hash + ":" + dbPath.Path
			if !processedDBPaths[key] {
				if diskHash, exists := diskFiles[dbPath.Path]; exists {
					results["MODIFIED"] = append(results["MODIFIED"], Result{Path: dbPath.Path, OriginalContentHash: hash, ContentHash: diskHash})
					processedDiskPaths[dbPath.Path] = true
				} else {
					results["DELETED"] = append(results["DELETED"], Result{Path: dbPath.Path, OriginalContentHash: hash})
				}
			}
		}
	}

	// Find truly new files (not processed as OK, MOVED, or MODIFIED)
	for relPath, diskHash := range diskFiles {
		if !processedDiskPaths[relPath] {
			results["NEW"] = append(results["NEW"], Result{Path: relPath, ContentHash: diskHash})
		}
	}

	// Handle RENAMED
	hashesWithMoved := make(map[string][]Result)
	for _, r := range results["MOVED"] {
		hashesWithMoved[r.ContentHash] = append(hashesWithMoved[r.ContentHash], r)
	}
	hashesWithDeleted := make(map[string][]Result)
	for _, r := range results["DELETED"] {
		hashesWithDeleted[r.OriginalContentHash] = append(hashesWithDeleted[r.OriginalContentHash], r)
	}

	for hash := range hashesWithMoved {
		if deleted, exists := hashesWithDeleted[hash]; exists {
			renamed := Result{
				ContentHash: hash,
				OldPaths:    getPathsFromResults(deleted),
				NewPaths:    getPathsFromResults(hashesWithMoved[hash]),
			}
			results["RENAMED"] = append(results["RENAMED"], renamed)
			// Remove from MOVED and DELETED
			results["MOVED"] = removeResults(results["MOVED"], hashesWithMoved[hash])
			results["DELETED"] = removeResults(results["DELETED"], deleted)
		}
	}

	// Output results
	fmt.Println("\n╔════════════════════════════════════════════════════════════════╗")
	fmt.Println("║              VERIFICATION RESULTS SUMMARY                      ║")
	fmt.Println("╚════════════════════════════════════════════════════════════════╝")
	fmt.Printf("  Total files on disk checked: %d\n", len(diskFiles))
	fmt.Printf("  Total unique checksums in DB: %d\n", len(checksumDB))
	fmt.Printf("  Database: %s\n", checksumFilePath)
	fmt.Println("────────────────────────────────────────────────────────────────")

	printResults("OK", results["OK"], "green")
	printResults("MODIFIED", results["MODIFIED"], "yellow")
	printResults("RENAMED", results["RENAMED"], "blue")
	printResults("MOVED", results["MOVED"], "blue")
	printResults("NEW", results["NEW"], "magenta")
	printResults("DELETED", results["DELETED"], "red")

	fmt.Println("────────────────────────────────────────────────────────────────")
	totalDiscrepancies := len(results["MODIFIED"]) + len(results["MOVED"]) + len(results["NEW"]) + len(results["DELETED"]) + len(results["RENAMED"])
	if totalDiscrepancies == 0 {
		fmt.Println("✓ All files are verified and match the checksum database.")
	} else {
		fmt.Printf("⚠ Found %d discrepancies. Review the details above.\n", totalDiscrepancies)
	}
	fmt.Println("════════════════════════════════════════════════════════════════")
}

func getPaths(entries []PathEntry) []string {
	var paths []string
	for _, e := range entries {
		paths = append(paths, e.Path)
	}
	return paths
}

func getPathsFromResults(results []Result) []string {
	var paths []string
	for _, r := range results {
		if r.Path != "" {
			paths = append(paths, r.Path)
		}
	}
	return paths
}

func removeResults(all []Result, toRemove []Result) []Result {
	var remaining []Result
	for _, r := range all {
		found := false
		for _, rem := range toRemove {
			if r.Path == rem.Path && r.ContentHash == rem.ContentHash {
				found = true
				break
			}
		}
		if !found {
			remaining = append(remaining, r)
		}
	}
	return remaining
}

func printResults(category string, results []Result, _ string) {
	if len(results) == 0 {
		return
	}

	// Use colored symbols
	symbol := "•"
	switch category {
	case "OK":
		symbol = "✓"
	case "MODIFIED":
		symbol = "⚠"
	case "MOVED", "RENAMED":
		symbol = "↔"
	case "NEW":
		symbol = "+"
	case "DELETED":
		symbol = "✗"
	}

	fmt.Printf("\n%s %s (%d):\n", symbol, category, len(results))
	for _, r := range results {
		switch category {
		case "OK":
			fmt.Printf("  • %s\n", r.Path)
		case "MODIFIED":
			fmt.Printf("  • %s\n", r.Path)
			fmt.Printf("    Original: %s\n", r.OriginalContentHash[:8]+"...")
			fmt.Printf("    Current:  %s\n", r.ContentHash[:8]+"...")
		case "MOVED":
			fmt.Printf("  • %s\n", r.Path)
			fmt.Printf("    Hash: %s\n", r.ContentHash[:8]+"...")
			fmt.Printf("    Previously at: %s\n", strings.Join(r.KnownOldPaths, ", "))
		case "NEW":
			fmt.Printf("  • %s (Hash: %s)\n", r.Path, r.ContentHash[:8]+"...")
		case "DELETED":
			fmt.Printf("  • %s (Hash: %s)\n", r.Path, r.OriginalContentHash[:8]+"...")
		case "RENAMED":
			fmt.Printf("  • Hash: %s\n", r.ContentHash[:8]+"...")
			fmt.Printf("    Old path(s): %s\n", strings.Join(r.OldPaths, ", "))
			fmt.Printf("    New path(s): %s\n", strings.Join(r.NewPaths, ", "))
		}
	}
}
