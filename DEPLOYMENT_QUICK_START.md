# 🚀 Quick Deployment Guide

## 5-Minute Quick Deployment Steps

### Prerequisites

- ✅ Connected to free MySQL server
- ✅ Code pushed to GitHub
- ✅ Registered Render.com and Vercel accounts

---

## Step 1: Deploy Backend (Laravel) to Render.com

### 1. Prepare Environment Variables

Before deployment, get the following information:

```bash
# Run in backend_services directory
cd backend_services
php artisan key:generate --show
```

Save the generated `APP_KEY`.

### 2. Deploy on Render.com

1. Visit https://render.com
2. Click "New +" → "Web Service"
3. Connect GitHub repository
4. Configure:

   - **Name**: `kalmnest-api`
   - **Root Directory**: `backend_services`
   - **Environment**: `PHP`
   - **Build Command**:
     ```bash
     composer install --no-dev --optimize-autoloader && php artisan config:cache && php artisan route:cache
     ```
   - **Start Command**:
     ```bash
     php -d register_argc_argv=On vendor/bin/heroku-php-apache2 public/
     ```

5. **Add Environment Variables**:

   ```env
   APP_NAME=Kalmnest
   APP_ENV=production
   APP_KEY=base64:YOUR_APP_KEY
   APP_DEBUG=false
   APP_URL=https://kalmnest-api.onrender.com

   DB_CONNECTION=mysql
   DB_HOST=your-mysql-host.com
   DB_PORT=3306
   DB_DATABASE=your_database_name
   DB_USERNAME=your_username
   DB_PASSWORD=your_password

   FRONTEND_URL=https://your-frontend.vercel.app
   SANCTUM_STATEFUL_DOMAINS=your-frontend.vercel.app
   SESSION_DOMAIN=.vercel.app
   ```

6. Click "Create Web Service"
7. Wait for deployment to complete (about 5-10 minutes)
8. Record your API URL: `https://kalmnest-api.onrender.com`

### 3. Run Database Migrations

After deployment, run in Render's Shell:

```bash
php artisan migrate --force
```

---

## Step 2: Update Flutter API Configuration

### Update API Address

Edit `flutter_codelab/lib/constants/api_constants.dart`:

```dart
static String get baseUrl {
  if (kIsWeb) {
    return 'https://kalmnest-api.onrender.com/api';  // Replace with your Render URL
  }
  // ... other configurations remain unchanged
}
```

---

## Step 3: Build Flutter Web

```bash
cd flutter_codelab
flutter build web --release
```

After build completes, files are in `flutter_codelab/build/web/` directory.

---

## Step 4: Deploy Frontend to Vercel

### Method 1: Via Vercel CLI (Recommended)

```bash
# Install Vercel CLI
npm i -g vercel

# Login
vercel login

# Deploy
cd flutter_codelab/build/web
vercel --prod
```

### Method 2: Via Vercel Website

1. Visit https://vercel.com
2. Click "Add New..." → "Project"
3. Select "Upload" or connect GitHub
4. If uploading:
   - Select `flutter_codelab/build/web` directory
   - Drag entire folder to Vercel
5. Configure:
   - **Framework Preset**: Other
   - **Root Directory**: `.` (current directory)
6. Click "Deploy"
7. Record your frontend URL: `https://your-app.vercel.app`

---

## Step 5: Update Backend CORS Configuration

In Render.com's environment variables, update:

```env
FRONTEND_URL=https://your-app.vercel.app
SANCTUM_STATEFUL_DOMAINS=your-app.vercel.app
```

Then redeploy backend.

---

## Step 6: Test

1. Visit frontend URL
2. Open browser developer tools (F12)
3. Test login/registration functionality
4. Check Network tab to confirm API calls succeed

---

## 🔧 Troubleshooting

### Issue: CORS Errors

**Solution**:

1. Check `allowed_origins` in `backend_services/config/cors.php`
2. Ensure frontend URL is in `FRONTEND_URL` environment variable
3. Redeploy backend

### Issue: Database Connection Failed

**Solution**:

1. Check if database host address is correct
2. Confirm database allows remote connections
3. Verify username and password

### Issue: Application Sleeping (Render Free Tier)

**Solution**:

- First access will be slow (needs to wake up)
- Or use UptimeRobot to regularly ping your application

---

## 📝 Environment Variables Checklist

### Backend (Render.com)

- [ ] `APP_KEY` - Laravel application key
- [ ] `DB_HOST` - MySQL host address
- [ ] `DB_DATABASE` - Database name
- [ ] `DB_USERNAME` - Database username
- [ ] `DB_PASSWORD` - Database password
- [ ] `FRONTEND_URL` - Frontend URL
- [ ] `SANCTUM_STATEFUL_DOMAINS` - Sanctum domain

### Frontend (Vercel)

- [ ] `API_URL` - Backend API URL (if needed)

---

## 🎉 Done!

Your application should now be successfully deployed!

- **Backend API**: `https://kalmnest-api.onrender.com`
- **Frontend App**: `https://your-app.vercel.app`

---

## 📚 More Information

For detailed deployment guide, see: `DEPLOYMENT_GUIDE.md`
