#!/bin/bash

# Flutter Web Deployment Script
# This script builds and prepares Flutter Web for deployment

echo "🚀 Starting Flutter Web deployment process..."

# Step 1: Navigate to Flutter project
cd flutter_codelab || exit

# Step 2: Get dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Step 3: Build for web
echo "🔨 Building Flutter Web (release mode)..."
flutter build web --release

# Step 4: Check if build succeeded
if [ -d "build/web" ]; then
    echo "✅ Build successful!"
    echo "📁 Build files are in: flutter_codelab/build/web"
    echo ""
    echo "📋 Next steps:"
    echo "1. Deploy to Vercel:"
    echo "   cd flutter_codelab/build/web"
    echo "   vercel --prod"
    echo ""
    echo "2. Or upload the build/web folder to your hosting service"
else
    echo "❌ Build failed! Please check the errors above."
    exit 1
fi

