# Build script for MD5 Checker - Cross-platform compilation
# Builds executables for Windows, Linux, and macOS

Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║              MD5 Checker - Multi-Platform Build                ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Extract version from version.go
$versionLine = Get-Content .\version.go | Select-String 'const Version = "(.+)"'
$version = $versionLine.Matches.Groups[1].Value
Write-Host "Building version: $version" -ForegroundColor Cyan
Write-Host ""

# Clean old builds
Write-Host "Cleaning old builds..." -ForegroundColor Yellow
Remove-Item -Path ".\bin" -Recurse -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path ".\bin" -Force | Out-Null

# Build for Windows (64-bit)
Write-Host "Building for Windows (amd64)..." -ForegroundColor Green
$env:GOOS = "windows"
$env:GOARCH = "amd64"
go build -o ".\bin\md5checker-windows-amd64_$version.exe"
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Windows build successful" -ForegroundColor Green
} else {
    Write-Host "✗ Windows build failed" -ForegroundColor Red
}

# Build for Linux (64-bit)
Write-Host "Building for Linux (amd64)..." -ForegroundColor Green
$env:GOOS = "linux"
$env:GOARCH = "amd64"
go build -o ".\bin\md5checker-linux-amd64_$version"
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Linux (amd64) build successful" -ForegroundColor Green
} else {
    Write-Host "✗ Linux (amd64) build failed" -ForegroundColor Red
}

# Build for Linux (ARM64)
Write-Host "Building for Linux (arm64)..." -ForegroundColor Green
$env:GOOS = "linux"
$env:GOARCH = "arm64"
go build -o ".\bin\md5checker-linux-arm64_$version"
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Linux (arm64) build successful" -ForegroundColor Green
} else {
    Write-Host "✗ Linux (arm64) build failed" -ForegroundColor Red
}

# Build for macOS (Intel)
Write-Host "Building for macOS (amd64)..." -ForegroundColor Green
$env:GOOS = "darwin"
$env:GOARCH = "amd64"
go build -o ".\bin\md5checker-darwin-amd64_$version"
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ macOS (Intel) build successful" -ForegroundColor Green
} else {
    Write-Host "✗ macOS (Intel) build failed" -ForegroundColor Red
}

# Build for macOS (Apple Silicon)
Write-Host "Building for macOS (arm64)..." -ForegroundColor Green
$env:GOOS = "darwin"
$env:GOARCH = "arm64"
go build -o ".\bin\md5checker-darwin-arm64_$version"
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ macOS (Apple Silicon) build successful" -ForegroundColor Green
} else {
    Write-Host "✗ macOS (Apple Silicon) build failed" -ForegroundColor Red
}

# Reset environment variables
Remove-Item Env:\GOOS
Remove-Item Env:\GOARCH

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Build complete! Executables are in the 'bin' directory:" -ForegroundColor Cyan
Write-Host "  • Windows (64-bit): md5checker-windows-amd64_$version.exe" -ForegroundColor White
Write-Host "  • Linux (64-bit): md5checker-linux-amd64_$version" -ForegroundColor White
Write-Host "  • Linux (ARM64): md5checker-linux-arm64_$version" -ForegroundColor White
Write-Host "  • macOS (Intel): md5checker-darwin-amd64_$version" -ForegroundColor White
Write-Host "  • macOS (Apple Silicon): md5checker-darwin-arm64_$version" -ForegroundColor White
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
