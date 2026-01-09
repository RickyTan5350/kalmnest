#!/bin/bash

# Flutter Web Build Script for Vercel
# This script downloads Flutter SDK and builds the web app

set -e

echo "🚀 Starting Flutter Web build for Vercel..."

# Step 1: Download and setup Flutter SDK
echo "📦 Downloading Flutter SDK..."
# Using Flutter 3.35.4 which includes Dart SDK 3.9.2
# Reference: https://flutterreleases.com
FLUTTER_VERSION="3.35.4"
FLUTTER_SDK_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"

echo "📥 Downloading Flutter ${FLUTTER_VERSION} (includes Dart 3.9.2)..."
# Download Flutter with retry mechanism
curl -L --progress-bar --retry 3 --retry-delay 5 "$FLUTTER_SDK_URL" -o flutter.tar.xz || {
    echo "❌ Failed to download Flutter ${FLUTTER_VERSION}"
    echo "💡 Trying alternative: using latest stable version..."
    # Fallback: try to get latest stable version (may have newer Dart)
    FLUTTER_VERSION="stable"
    FLUTTER_SDK_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
    curl -L --progress-bar --retry 3 --retry-delay 5 "$FLUTTER_SDK_URL" -o flutter.tar.xz || {
        echo "❌ Failed to download Flutter SDK after retry"
        exit 1
    }
    echo "⚠️  Using fallback Flutter version - Dart version may differ"
}

echo "📦 Extracting Flutter SDK..."
# Extract Flutter
tar xf flutter.tar.xz || {
    echo "❌ Failed to extract Flutter SDK"
    exit 1
}

# Clean up downloaded archive
rm -f flutter.tar.xz

# Add Flutter to PATH
export PATH="$PATH:$PWD/flutter/bin"

# Fix Git safe directory warning (for Flutter's internal git operations)
git config --global --add safe.directory "$PWD/flutter" || true
git config --global --add safe.directory '*' || true

# Verify Flutter installation and check Dart version
echo "✅ Verifying Flutter installation..."
flutter --version

# Check Dart SDK version
DART_VERSION=$(flutter --version | grep -oP 'Dart SDK version: \K[0-9.]+' || echo "unknown")
echo "📌 Dart SDK version: $DART_VERSION"

# Verify Dart version meets requirement (should be >= 3.9.2)
if [[ "$DART_VERSION" != "unknown" ]]; then
    DART_MAJOR=$(echo "$DART_VERSION" | cut -d. -f1)
    DART_MINOR=$(echo "$DART_VERSION" | cut -d. -f2)
    DART_PATCH=$(echo "$DART_VERSION" | cut -d. -f3)
    
    # Check if version is >= 3.9.2
    VERSION_OK=false
    if [[ "$DART_MAJOR" -gt 3 ]]; then
        VERSION_OK=true
    elif [[ "$DART_MAJOR" -eq 3 ]]; then
        if [[ "$DART_MINOR" -gt 9 ]]; then
            VERSION_OK=true
        elif [[ "$DART_MINOR" -eq 9 ]]; then
            if [[ -n "$DART_PATCH" ]] && [[ "$DART_PATCH" -ge 2 ]]; then
                VERSION_OK=true
            fi
        fi
    fi
    
    if [[ "$VERSION_OK" == "true" ]]; then
        echo "✅ Dart SDK version $DART_VERSION meets requirement (^3.9.2)"
    else
        echo "⚠️  Warning: Dart SDK version $DART_VERSION does not meet requirement (^3.9.2)"
        echo "💡 Expected Flutter 3.35.4 with Dart 3.9.2, but got Dart $DART_VERSION"
        echo "⚠️  Continuing build - this may fail during 'flutter pub get'"
    fi
else
    echo "⚠️  Could not determine Dart SDK version"
fi

# Step 2: Get Flutter dependencies
echo "📦 Getting Flutter dependencies..."
cd flutter_codelab
flutter pub get

# Step 3: Build for web
echo "🔨 Building Flutter Web (release mode)..."
flutter build web --release --base-href /

# Step 4: Verify build
if [ -d "build/web" ]; then
    echo "✅ Build successful!"
    echo "📁 Build files are in: flutter_codelab/build/web"
    ls -la build/web
else
    echo "❌ Build failed! Build directory not found."
    exit 1
fi

echo "✅ Flutter Web build completed successfully!"
