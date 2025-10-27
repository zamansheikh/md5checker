# 🔐 MD5 Hash Checker

[![Go Version](https://img.shields.io/badge/Go-1.21+-00ADD8?style=flat&logo=go)](https://go.dev/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![GitHub Release](https://img.shields.io/github/v/release/zamansheikh/md5checker)](https://github.com/zamansheikh/md5checker/releases)
[![Build Status](https://github.com/zamansheikh/md5checker/workflows/Build%20and%20Release/badge.svg)](https://github.com/zamansheikh/md5checker/actions)

A fast, efficient, and user-friendly file integrity verification tool that uses **content-addressable storage** to track file checksums. Built with Go for cross-platform compatibility.

## ✨ Features

- 🎯 **Content-Addressable Storage** - Files with identical content share the same hash entry, regardless of name or location
- 📦 **Compressed Database** - All checksums stored in a single gzipped JSON file for minimal disk usage
- 🔍 **Smart Detection** - Automatically detects:
  - ✅ **OK** - Files with matching checksums
  - 📝 **MODIFIED** - Files with changed content
  - 🚚 **MOVED** - Files relocated to different paths
  - 🏷️ **RENAMED** - Files with changed names but same content
  - ➕ **NEW** - Files not in the database
  - ❌ **DELETED** - Files removed from disk
- 🚀 **Dual Operation Modes**:
  - **Add New Files** - Incrementally add new files without updating existing checksums
  - **Regenerate All** - Create a fresh baseline by updating all checksums
- 🌍 **Cross-Platform** - Pre-built binaries for Windows, Linux (AMD64/ARM64), and macOS (Intel/Apple Silicon)
- 💾 **Efficient** - Excludes binary executables and database files automatically
- 🎨 **Beautiful CLI** - Clean, professional terminal interface with Unicode symbols

## 📸 Screenshots

```
=======================================
         MD5 Hash Checker
      (Content-Addressable)
         Version v1.0.0
=======================================
  Developed by Md. Shamsuzzaman
  GitHub: github.com/zamansheikh
  Facebook: facebook.com/zamansheikh.404
=======================================

────────────────────────────────────────
 MD5 Hash Checker 
 (Content-Addressable) 
────────────────────────────────────────
1. Add New Files to Database
2. Regenerate All Checksums
3. Verify File Integrity
4. Show Manual/Instructions
5. Exit
────────────────────────────────────────
```

## 🚀 Quick Start

### Installation

#### Option 1: Download Pre-built Binaries (Recommended)

Download the latest release for your platform from the [Releases](https://github.com/zamansheikh/md5checker/releases) page:

| Platform | Binary |
|----------|--------|
| Windows (64-bit) | `md5checker-windows-amd64_v1.0.0.exe` |
| Linux (64-bit) | `md5checker-linux-amd64_v1.0.0` |
| Linux (ARM64) | `md5checker-linux-arm64_v1.0.0` |
| macOS (Intel) | `md5checker-darwin-amd64_v1.0.0` |
| macOS (Apple Silicon) | `md5checker-darwin-arm64_v1.0.0` |

**Linux/macOS users:** Make the binary executable
```bash
chmod +x md5checker-*
```

#### Option 2: Build from Source

```bash
# Clone the repository
git clone https://github.com/zamansheikh/md5checker.git
cd md5checker

# Build for your platform
go build -o md5checker

# Or build for all platforms
./build.sh    # Linux/macOS
.\build.ps1   # Windows
```

### Usage

Simply run the executable:

```bash
# Windows
.\md5checker.exe

# Linux/macOS
./md5checker
```

## 📖 How It Works

### Content-Addressable Storage

Unlike traditional checksum tools that store one file-per-path, MD5 Checker uses **content-addressable storage**:

```json
{
  "abc123def456...": {
    "contentMD5": "abc123def456...",
    "relativePaths": [
      {
        "path": "documents/file1.txt",
        "firstSeen": "2025-01-15T10:30:00Z",
        "lastSeen": "2025-01-20T14:22:00Z"
      },
      {
        "path": "backup/file1_copy.txt",
        "firstSeen": "2025-01-18T09:15:00Z",
        "lastSeen": "2025-01-20T14:22:00Z"
      }
    ],
    "firstCreated": "2025-01-15T10:30:00Z",
    "lastContentUpdate": "2025-01-20T14:22:00Z"
  }
}
```

**Benefits:**
- Multiple files with identical content share one database entry
- Automatically detects file moves and renames
- Tracks file history across multiple paths
- Reduces database size for duplicate content

### Workflow

#### 1️⃣ **Add New Files to Database**

Use this when you want to **add newly created files** without updating checksums for existing files:

```bash
Choose option: 1
```

- Scans all files in the current directory
- Adds only NEW files not in the database
- Existing files keep their original checksums
- **Use case:** Daily workflow to track new downloads, documents, etc.

#### 2️⃣ **Regenerate All Checksums**

Use this when you want to **create a fresh baseline** by updating ALL checksums:

```bash
Choose option: 2
```

- Recalculates checksums for ALL files
- Updates existing entries with current content
- **Use case:** After intentional file modifications, system updates, or initial setup

#### 3️⃣ **Verify File Integrity**

Check for changes, moves, deletions, and new files:

```bash
Choose option: 3
```

**Detection Results:**
- ✅ **OK** - File content matches database (1234 files)
- 📝 **MODIFIED** - Content changed (5 files)
- 🚚 **MOVED** - File relocated but content unchanged (2 files)
- 🏷️ **RENAMED** - Same content, different name (1 file)
- ➕ **NEW** - File not in database (10 files)
- ❌ **DELETED** - File in database but missing from disk (3 files)

## 🎯 Use Cases

### 1. **Software Development**
Verify build artifacts haven't been tampered with:
```bash
# After building your project
md5checker   # Choose: Regenerate All
# Before deploying
md5checker   # Choose: Verify Integrity
```

### 2. **Data Archival**
Ensure long-term storage integrity:
```bash
# When archiving files
md5checker   # Regenerate All
# Periodic verification
md5checker   # Verify Integrity
```

### 3. **System Administration**
Monitor critical system files:
```bash
# Baseline after fresh install
cd /etc && md5checker   # Regenerate All
# Regular audits
cd /etc && md5checker   # Verify Integrity
```

### 4. **Digital Forensics**
Track file changes across investigations:
```bash
# Initial capture
md5checker   # Regenerate All
# Compare later states
md5checker   # Verify Integrity
```

### 5. **Media Libraries**
Detect duplicate photos/videos and track moves:
```bash
cd ~/Photos && md5checker   # Add New Files
md5checker   # Verify - shows moved/renamed media
```

## 🏗️ Architecture

### Project Structure

```
md5checker/
├── main.go              # Entry point, menu system, banner
├── generate.go          # Checksum generation logic
├── verify.go            # Integrity verification logic
├── utils.go             # Utility functions
├── version.go           # Version constant
├── build.ps1            # Windows build script
├── build.sh             # Linux/macOS build script
├── go.mod               # Go module definition
├── README.md            # This file
├── .gitignore           # Git ignore rules
└── .github/
    └── workflows/
        └── release.yml  # Automated release pipeline
```

### Data Structures

```go
type InfoData struct {
    ContentMD5        string      // MD5 hash of file content
    RelativePaths     []PathEntry // All known paths for this content
    FirstCreated      time.Time   // When first seen
    LastContentUpdate time.Time   // When last updated
}

type PathEntry struct {
    Path      string    // Relative file path
    FirstSeen time.Time // When path first appeared
    LastSeen  time.Time // When path last verified
}
```

### Database

- **Format:** JSON (gzipped)
- **Location:** `checksums.json.gz` (same directory as executable)
- **Structure:** Map of MD5 hash → InfoData
- **Compression:** ~70-80% size reduction with gzip

## 🛠️ Development

### Prerequisites

- Go 1.21 or higher
- Git

### Building

```bash
# Clone the repository
git clone https://github.com/zamansheikh/md5checker.git
cd md5checker

# Install dependencies
go mod download

# Build for current platform
go build -o md5checker

# Build for all platforms
./build.sh    # Creates bin/ directory with all binaries
```

### Build Scripts

Both `build.ps1` (PowerShell) and `build.sh` (Bash) support:
- Automatic version extraction from `version.go`
- Cross-compilation for 5 platforms
- Versioned binary naming: `md5checker-{os}-{arch}_{version}`

### Release Process

1. Update version in `version.go`:
   ```go
   const Version = "v1.1.0"
   ```

2. Commit changes:
   ```bash
   git add version.go
   git commit -m "Bump version to v1.1.0"
   ```

3. Create and push tag:
   ```bash
   git tag v1.1.0
   git push origin v1.1.0
   ```

4. GitHub Actions automatically:
   - Builds binaries for all platforms
   - Creates a GitHub Release
   - Uploads all binaries as release assets

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. 🐛 **Report Bugs** - Open an issue with detailed reproduction steps
2. 💡 **Suggest Features** - Share your ideas for improvements
3. 🔧 **Submit Pull Requests** - Fix bugs or implement features
4. 📖 **Improve Documentation** - Help make the docs clearer
5. ⭐ **Star the Project** - Show your support!

### Development Guidelines

- Follow Go best practices and idioms
- Add tests for new features
- Update documentation for API changes
- Use descriptive commit messages
- Keep PRs focused and atomic

## 📋 Roadmap

- [ ] SHA-256 and SHA-512 support
- [ ] Parallel file processing for large directories
- [ ] JSON/CSV export for verification reports
- [ ] Watch mode for real-time monitoring
- [ ] GUI application (Electron or native)
- [ ] Configuration file support
- [ ] Cloud storage integration (S3, Azure Blob)
- [ ] Exclude patterns (regex/glob)

## ❓ FAQ

### Q: How is this different from other checksum tools?

**A:** MD5 Checker uses content-addressable storage, meaning:
- Multiple files with the same content share one database entry
- Automatically detects file moves and renames
- Tracks file history across multiple paths
- More efficient for duplicate-heavy environments

### Q: Why MD5? Isn't it broken for security?

**A:** You're right that MD5 is not suitable for cryptographic purposes. However, for **file integrity checking** (detecting accidental corruption, moves, or changes), MD5 is:
- Fast and efficient
- Perfectly adequate for non-adversarial scenarios
- Universally supported
- Collision-resistant enough for practical file verification

**Future versions will support SHA-256/SHA-512 for security-sensitive use cases.**

### Q: Can I use this on large directories?

**A:** Yes! The tool is designed for efficiency:
- Compressed database (gzip)
- Content-addressable storage (deduplication)
- Streaming file processing
- Automatic exclusion of binaries

For very large directories (100k+ files), consider:
- Using exclude patterns (future feature)
- Running in subdirectories
- Using SSD storage for better I/O performance

### Q: What happens if I modify a file?

**A:** Depends on your workflow:

1. **If you use "Add New Files":**
   - Original checksum is preserved
   - "Verify" will show file as MODIFIED

2. **If you use "Regenerate All":**
   - New checksum replaces old one
   - "Verify" will show file as OK

**Recommendation:** Use "Add New Files" for daily workflow, "Regenerate All" when you intentionally modify files.

### Q: How do I ignore certain files?

**A:** Currently, the tool automatically excludes:
- The database file (`checksums.json.gz`)
- All md5checker binaries (any platform)

**Manual exclusion:** Delete entries from `checksums.json.gz` (decompress, edit JSON, recompress) or use future exclude pattern feature.

### Q: Can I use this in scripts/automation?

**A:** Not yet - the current version is interactive. Future versions will support:
- Command-line flags for non-interactive operation
- Exit codes for script integration
- JSON output for parsing

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Md. Shamsuzzaman**

- 🐙 GitHub: [@zamansheikh](https://github.com/zamansheikh)
- 📘 Facebook: [zamansheikh.404](https://facebook.com/zamansheikh.404)
- 💼 LinkedIn: [Connect with me](https://linkedin.com/in/zamansheikh)

## 🌟 Support

If you find this project useful, please consider:

- ⭐ **Starring** the repository
- 🐛 **Reporting bugs** or suggesting features
- 📢 **Sharing** with others who might benefit
- 💖 **Contributing** to make it better

---

<div align="center">

**Made with ❤️ by Md. Shamsuzzaman**

[⬆ Back to Top](#-md5-hash-checker)

</div>
