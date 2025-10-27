// MD5 Hash Checker (Content-Addressable)
// Developed by Md. Shamsuzzaman
// GitHub: github.com/zamansheikh
// Facebook: facebook.com/zamansheikh.404

package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

func main() {
	showBanner()
	reader := bufio.NewReader(os.Stdin)
	for {
		showMenu()
		choice, _ := reader.ReadString('\n')
		choice = strings.TrimSpace(choice)
		switch choice {
		case "1":
			NewMD5Hashes(false) // Add new files only
		case "2":
			NewMD5Hashes(true) // Regenerate all checksums
		case "3":
			TestMD5Hashes() // Verify
		case "4":
			ShowManual()
		case "5":
			fmt.Println("Exiting the program.")
			os.Exit(0)
		default:
			fmt.Println("Invalid option, please try again.")
		}
		fmt.Println("\nPress Enter to return to the menu...")
		reader.ReadString('\n') // Wait for input
		clearScreen()
		showBanner()
	}
}

func clearScreen() {
	// Clear screen for Windows
	fmt.Print("\033[H\033[2J")
}

func showMenu() {
	fmt.Println("────────────────────────────────────────")
	fmt.Println(" MD5 Hash Checker ")
	fmt.Println(" (Content-Addressable) ")
	fmt.Println("────────────────────────────────────────")
	fmt.Println("1. Add New Files to Database")
	fmt.Println("2. Regenerate All Checksums")
	fmt.Println("3. Verify File Integrity")
	fmt.Println("4. Show Manual/Instructions")
	fmt.Println("5. Exit")
	fmt.Println("────────────────────────────────────────")
	fmt.Print("Choose an option: ")
}

func showBanner() {
	fmt.Println("=======================================")
	fmt.Println("         MD5 Hash Checker")
	fmt.Println("      (Content-Addressable)")
	fmt.Printf("              Version %s\n", Version)
	fmt.Println("=======================================")
	fmt.Println("  Developed by Md. Shamsuzzaman")
	fmt.Println("  GitHub: github.com/zamansheikh")
	fmt.Println("  Facebook: facebook.com/zamansheikh.404")
	fmt.Println("=======================================")
	fmt.Println()
}

func ShowManual() {
	fmt.Println("╔════════════════════════════════════════════════════════════════╗")
	fmt.Println("║                   MD5 HASH CHECKER MANUAL                      ║")
	fmt.Println("╚════════════════════════════════════════════════════════════════╝")
	fmt.Println()
	fmt.Println("OVERVIEW:")
	fmt.Println("This tool provides content-addressable MD5 checksum verification.")
	fmt.Println("It helps detect file integrity changes, moves, renames, additions,")
	fmt.Println("and deletions in your file system.")
	fmt.Println()
	fmt.Println("HOW IT WORKS:")
	fmt.Println("• Files are scanned recursively from the current directory")
	fmt.Println("• MD5 hashes are computed for each file's content")
	fmt.Println("• Checksums are stored in a compressed database (checksums.json.gz)")
	fmt.Println("• Multiple paths can share the same content hash with timestamps")
	fmt.Println()
	fmt.Println("────────────────────────────────────────────────────────────────")
	fmt.Println("MENU OPTIONS:")
	fmt.Println("────────────────────────────────────────────────────────────────")
	fmt.Println()
	fmt.Println("1. Add New Files to Database")
	fmt.Println("   → Scans for files not yet in the database")
	fmt.Println("   → ONLY adds new files, does NOT update existing ones")
	fmt.Println("   → Use this when you add new files to your directory")
	fmt.Println("   → Modified files will still show as modified on verification")
	fmt.Println()
	fmt.Println("2. Regenerate All Checksums")
	fmt.Println("   → Rescans ALL files and updates their checksums")
	fmt.Println("   → Updates checksums for modified files")
	fmt.Println("   → Use this to create a fresh baseline after intentional changes")
	fmt.Println("   → WARNING: This will overwrite existing checksums!")
	fmt.Println()
	fmt.Println("3. Verify File Integrity")
	fmt.Println("   → Compares current files against stored checksums")
	fmt.Println("   → Reports: OK, MODIFIED, MOVED, NEW, DELETED, RENAMED")
	fmt.Println("   → Use this to check for any changes since last generation")
	fmt.Println()
	fmt.Println("4. Show Manual/Instructions")
	fmt.Println("   → Displays this help information")
	fmt.Println()
	fmt.Println("5. Exit")
	fmt.Println("   → Quits the program")
	fmt.Println()
	fmt.Println("────────────────────────────────────────────────────────────────")
	fmt.Println("TYPICAL WORKFLOW:")
	fmt.Println("────────────────────────────────────────────────────────────────")
	fmt.Println("1. First time: Use option 2 to create initial database")
	fmt.Println("2. Add files: Use option 1 to add new files only")
	fmt.Println("3. Check integrity: Use option 3 to detect any modifications")
	fmt.Println("4. After intentional changes: Use option 2 to update baseline")
	fmt.Println()
	fmt.Println("────────────────────────────────────────────────────────────────")
	fmt.Println("NOTES:")
	fmt.Println("────────────────────────────────────────────────────────────────")
	fmt.Println("• Database file: checksums.json.gz (compressed)")
	fmt.Println("• Excluded files: md5checker.exe, checksums.json.gz")
	fmt.Println("• For large directories, operations may take time")
	fmt.Println("• Database is portable - can be copied/backed up")
	fmt.Println()
	fmt.Println("════════════════════════════════════════════════════════════════")
	fmt.Println("Developed by Md. Shamsuzzaman")
	fmt.Println("GitHub: github.com/zamansheikh")
	fmt.Println("Facebook: facebook.com/zamansheikh.404")
	fmt.Println("════════════════════════════════════════════════════════════════")
}
