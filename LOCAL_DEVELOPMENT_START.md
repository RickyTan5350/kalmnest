# 🚀 Local Development Quick Start

## ✅ Code Changes Applied

The following code has been modified to switch to localhost:

### Frontend Changes
- **File**: `flutter_codelab/lib/constants/api_constants.dart`
  - API URL: Changed to `https://kalmnest.test/api` (Laravel Herd)
  - Domain URL: Changed to `https://kalmnest.test` (Laravel Herd)

---

## 🏃 Quick Start

### Step 1: Start Backend (Laravel Herd)

**Using Laravel Herd** (Recommended):

1. **Ensure Laravel Herd is running**
   - Check Herd status in system tray/menu bar
   - Herd automatically serves sites in configured directories

2. **Configure your project in Herd**:
   ```bash
   cd backend_services
   
   # Herd should automatically detect your Laravel project
   # If not, link it manually:
   herd link kalmnest
   ```

3. **Ensure .env file is configured**:
   ```env
   APP_ENV=local
   APP_DEBUG=true
   APP_URL=https://kalmnest.test
   DB_CONNECTION=mysql
   DB_HOST=your-mysql-host
   DB_DATABASE=your_database
   DB_USERNAME=your_username
   DB_PASSWORD=your_password
   ```

4. **Clear cache**:
   ```bash
   cd backend_services
   php artisan config:clear
   php artisan cache:clear
   ```

**Backend will run on**: `https://kalmnest.test`

**Alternative: Using php artisan serve** (if not using Herd):
```bash
cd backend_services
php artisan serve
# Backend will run on http://localhost:8000
# Then update api_constants.dart to use http://localhost:8000/api
```

### Step 2: Start Frontend (Flutter Web)

Open a **new terminal**:

```bash
cd flutter_codelab

# Run Flutter Web in development mode
flutter run -d chrome
```

**Frontend will run on**: `http://localhost:xxxx` (port assigned by Flutter)

---

## ✅ Verify Everything Works

1. **Backend**: Open `https://kalmnest.test/api` - should see API response
2. **Frontend**: Open the Flutter Web URL - should load the app
3. **Test**: Try logging in - should connect to local backend via Herd

---

## 🔄 To Switch Back to Production

When you're done with local development:

1. **Revert frontend code**:
   - Change `https://kalmnest.test/api` back to `https://kalmnest-api.onrender.com/api`
   - Change `https://kalmnest.test` back to `https://kalmnest-api.onrender.com`

2. **Or use Git**:
   ```bash
   git checkout flutter_codelab/lib/constants/api_constants.dart
   ```

---

## 📝 Notes

- **Database**: Still uses your remote MySQL server (no changes needed)
- **CORS**: Already configured to allow localhost and .test domains
- **Backend**: Using Laravel Herd - no need to run `php artisan serve`
- **HTTPS**: Herd automatically provides HTTPS with self-signed certificates
- **Domain**: `kalmnest.test` is configured in Herd (or your hosts file)

---

**You're all set for local development!** 🎉

