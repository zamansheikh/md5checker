#!/bin/bash

# Build script for MD5 Checker - Cross-platform compilation
# Builds executables for Windows, Linux, and macOS

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              MD5 Checker - Multi-Platform Build                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Extract version from version.go
VERSION=$(grep 'const Version = ' version.go | sed 's/.*"\(.*\)".*/\1/')
echo "Building version: $VERSION"
echo ""

# Clean old builds
echo "Cleaning old builds..."
rm -rf ./bin
mkdir -p ./bin

# Build for Windows (64-bit)
echo "Building for Windows (amd64)..."
GOOS=windows GOARCH=amd64 go build -o "./bin/md5checker-windows-amd64_${VERSION}.exe"
if [ $? -eq 0 ]; then
    echo "✓ Windows build successful"
else
    echo "✗ Windows build failed"
fi

# Build for Linux (64-bit)
echo "Building for Linux (amd64)..."
GOOS=linux GOARCH=amd64 go build -o "./bin/md5checker-linux-amd64_${VERSION}"
if [ $? -eq 0 ]; then
    echo "✓ Linux (amd64) build successful"
else
    echo "✗ Linux (amd64) build failed"
fi

# Build for Linux (ARM64)
echo "Building for Linux (arm64)..."
GOOS=linux GOARCH=arm64 go build -o "./bin/md5checker-linux-arm64_${VERSION}"
if [ $? -eq 0 ]; then
    echo "✓ Linux (arm64) build successful"
else
    echo "✗ Linux (arm64) build failed"
fi

# Build for macOS (Intel)
echo "Building for macOS (amd64)..."
GOOS=darwin GOARCH=amd64 go build -o "./bin/md5checker-darwin-amd64_${VERSION}"
if [ $? -eq 0 ]; then
    echo "✓ macOS (Intel) build successful"
else
    echo "✗ macOS (Intel) build failed"
fi

# Build for macOS (Apple Silicon)
echo "Building for macOS (arm64)..."
GOOS=darwin GOARCH=arm64 go build -o "./bin/md5checker-darwin-arm64_${VERSION}"
if [ $? -eq 0 ]; then
    echo "✓ macOS (Apple Silicon) build successful"
else
    echo "✗ macOS (Apple Silicon) build failed"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "Build complete! Executables are in the 'bin' directory:"
echo "  • Windows (64-bit): md5checker-windows-amd64_${VERSION}.exe"
echo "  • Linux (64-bit): md5checker-linux-amd64_${VERSION}"
echo "  • Linux (ARM64): md5checker-linux-arm64_${VERSION}"
echo "  • macOS (Intel): md5checker-darwin-amd64_${VERSION}"
echo "  • macOS (Apple Silicon): md5checker-darwin-arm64_${VERSION}"
echo "════════════════════════════════════════════════════════════════"
