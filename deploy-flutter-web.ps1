# Flutter Web Deployment Script for Windows PowerShell
# This script builds and prepares Flutter Web for deployment

Write-Host "🚀 Starting Flutter Web deployment process..." -ForegroundColor Green

# Step 1: Navigate to Flutter project
Set-Location flutter_codelab

# Step 2: Get dependencies
Write-Host "📦 Getting Flutter dependencies..." -ForegroundColor Yellow
flutter pub get

# Step 3: Build for web
Write-Host "🔨 Building Flutter Web (release mode)..." -ForegroundColor Yellow
flutter build web --release

# Step 4: Check if build succeeded
if (Test-Path "build\web") {
    Write-Host "✅ Build successful!" -ForegroundColor Green
    Write-Host "📁 Build files are in: flutter_codelab\build\web" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📋 Next steps:" -ForegroundColor Yellow
    Write-Host "1. Deploy to Vercel:" -ForegroundColor White
    Write-Host "   cd flutter_codelab\build\web" -ForegroundColor Gray
    Write-Host "   vercel --prod" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Or upload the build\web folder to your hosting service" -ForegroundColor White
} else {
    Write-Host "❌ Build failed! Please check the errors above." -ForegroundColor Red
    exit 1
}

