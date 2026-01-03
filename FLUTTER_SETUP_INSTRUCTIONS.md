# Flutter Setup Instructions After Merge

## ✅ Fixed Issue
- **Problem**: Duplicate `flutter_markdown` entry in `pubspec.yaml`
- **Solution**: Removed duplicate, kept newer version (`^0.7.7+1`)

## Steps to Run Flutter

### 1. Navigate to Flutter Project
```bash
cd flutter_codelab
```

### 2. Clean Flutter Project
```bash
flutter clean
```

### 3. Get Dependencies
```bash
flutter pub get
```

### 4. Generate Localization Files (if needed)
```bash
flutter gen-l10n
```

### 5. Run the App
```bash
# For web
flutter run -d chrome

# For Android
flutter run

# For iOS (Mac only)
flutter run -d ios
```

## If You Get Errors

### Error: Flutter command not found
- Make sure Flutter is in your PATH
- Or use full path: `C:\path\to\flutter\bin\flutter clean`

### Error: Dependencies issues
```bash
flutter pub get
flutter pub upgrade
```

### Error: Localization issues
```bash
flutter gen-l10n
```

## Backend Setup (if needed)

### 1. Navigate to Backend
```bash
cd backend_services
```

### 2. Install Dependencies
```bash
composer install
```

### 3. Run Migrations
```bash
php artisan migrate
```

### 4. Start Server
```bash
# Using Laravel Herd (if installed)
# Or using artisan
php artisan serve
```

## Quick Start Commands

```bash
# Terminal 1: Backend
cd backend_services
php artisan serve

# Terminal 2: Flutter
cd flutter_codelab
flutter run -d chrome
```

