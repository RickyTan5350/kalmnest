#!/bin/bash

# Flutter Web Build Script for Vercel
# This script downloads Flutter SDK and builds the web app

set -e

echo "🚀 Starting Flutter Web build for Vercel..."

# Step 1: Download and setup Flutter SDK
echo "📦 Downloading Flutter SDK..."
FLUTTER_VERSION="3.24.3"
FLUTTER_SDK_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"

# Download Flutter
curl -L "$FLUTTER_SDK_URL" -o flutter.tar.xz

# Extract Flutter
tar xf flutter.tar.xz

# Add Flutter to PATH
export PATH="$PATH:$PWD/flutter/bin"

# Verify Flutter installation
flutter --version

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
