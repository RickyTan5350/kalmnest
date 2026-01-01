# Application Deployment Guide - Free Deployment Solutions

This guide will help you deploy your Laravel backend and Flutter Web frontend to free cloud platforms.

## 📋 Deployment Architecture Overview

```
┌─────────────────┐
│  Flutter Web    │  → Deploy to Vercel/Netlify (Frontend)
│   (Frontend)    │
└────────┬────────┘
         │ API Calls
         ▼
┌─────────────────┐
│  Laravel API    │  → Deploy to Render/Railway (Backend)
│   (Backend)     │
└────────┬────────┘
         │ Database Connection
         ▼
┌─────────────────┐
│   MySQL Server  │  → Your configured free MySQL
└─────────────────┘
```

---

## 🎯 Deployment Process Overview

### Step 1: Prepare Code

1. ✅ Ensure code is pushed to GitHub
2. ✅ Configure environment variables
3. ✅ Test local run

### Step 2: Deploy Backend (Laravel)

1. Choose platform (Recommended: Render.com)
2. Connect GitHub repository
3. Configure environment variables
4. Set build commands
5. Deploy

### Step 3: Deploy Frontend (Flutter Web)

1. Build Flutter Web
2. Choose platform (Recommended: Vercel)
3. Upload build files
4. Configure API address

### Step 4: Configure CORS and Connection

1. Update backend CORS settings
2. Update frontend API address
3. Test connection

---

## 🚀 Solution 1: Render.com (Backend) + Vercel (Frontend) - Recommended

### Advantages:

- ✅ Completely free (with usage limits)
- ✅ Auto-deployment
- ✅ Simple and easy to use
- ✅ Supports Laravel
- ✅ Supports static websites

### Limitations:

- Render free tier: Applications sleep after 15 minutes of inactivity
- Vercel free tier: 100GB bandwidth per month

---

## 📦 Part 1: Deploy Laravel Backend to Render.com

### Step 1: Prepare Laravel Project

#### 1.1 Create `render.yaml` Configuration File

Create `render.yaml` in the `backend_services/` directory:

```yaml
services:
  - type: web
    name: kalmnest-api
    runtime: php
    plan: free
    buildCommand: |
      composer install --no-dev --optimize-autoloader
      php artisan config:cache
      php artisan route:cache
      php artisan view:cache
    startCommand: php -d register_argc_argv=On vendor/bin/heroku-php-apache2 public/
    envVars:
      - key: APP_ENV
        value: production
      - key: APP_DEBUG
        value: false
      - key: LOG_CHANNEL
        value: stderr
      - key: LOG_LEVEL
        value: error
```

#### 1.2 Create `Procfile` (Optional, Render also supports this)

Create `Procfile` in the `backend_services/` directory:

```
web: vendor/bin/heroku-php-apache2 public/
```

#### 1.3 Create `.htaccess` File (if it doesn't exist)

Ensure `backend_services/public/.htaccess` exists:

```apache
<IfModule mod_rewrite.c>
    <IfModule mod_negotiation.c>
        Options -MultiViews -Indexes
    </IfModule>

    RewriteEngine On

    # Handle Authorization Header
    RewriteCond %{HTTP:Authorization} .
    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]

    # Redirect Trailing Slashes If Not A Folder...
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_URI} (.+)/$
    RewriteRule ^ %1 [L,R=301]

    # Send Requests To Front Controller...
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteRule ^ index.php [L]
</IfModule>
```

#### 1.4 Update CORS Configuration

Check or create `backend_services/config/cors.php`:

```php
<?php

return [
    'paths' => ['api/*', 'sanctum/csrf-cookie'],
    'allowed_methods' => ['*'],
    'allowed_origins' => [
        'http://localhost:3000',
        'http://localhost:8080',
        env('FRONTEND_URL', 'https://your-frontend.vercel.app'),
    ],
    'allowed_origins_patterns' => [],
    'allowed_headers' => ['*'],
    'exposed_headers' => [],
    'max_age' => 0,
    'supports_credentials' => true,
];
```

### Step 2: Deploy on Render.com

1. **Register Account**

   - Visit https://render.com
   - Sign in with GitHub account (recommended)

2. **Create New Web Service**

   - Click "New +" → "Web Service"
   - Connect your GitHub repository
   - Select `backend_services` directory

3. **Configure Service**

   - **Name**: `kalmnest-api`
   - **Environment**: `PHP`
   - **Build Command**:
     ```bash
     composer install --no-dev --optimize-autoloader && php artisan config:cache && php artisan route:cache
     ```
   - **Start Command**:
     ```bash
     php -d register_argc_argv=On vendor/bin/heroku-php-apache2 public/
     ```

4. **Set Environment Variables**
   Add in Render's Environment Variables:

   ```env
   APP_NAME=Kalmnest
   APP_ENV=production
   APP_KEY=base64:YOUR_APP_KEY_HERE
   APP_DEBUG=false
   APP_URL=https://your-api.onrender.com

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

   **Important**: Generate APP_KEY

   ```bash
   php artisan key:generate --show
   ```

5. **Deploy**
   - Click "Create Web Service"
   - Render will automatically start building and deploying
   - Wait 5-10 minutes for deployment to complete
   - You'll get a URL, e.g.: `https://kalmnest-api.onrender.com`

### Step 3: Run Database Migrations

After deployment, run in Render's Shell:

```bash
php artisan migrate --force
```

Or use Render's Deploy Script:

```bash
composer install --no-dev --optimize-autoloader
php artisan migrate --force
php artisan config:cache
php artisan route:cache
```

---

## 🌐 Part 2: Deploy Flutter Web to Vercel

### Step 1: Build Flutter Web

Run in project root directory:

```bash
cd flutter_codelab
flutter build web --release
```

After build completes, files will be in `flutter_codelab/build/web/` directory.

### Step 2: Update API Address

In Flutter code, find API configuration (usually in `lib/services/` or `lib/config/`), update to:

```dart
// Example: lib/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'https://your-api.onrender.com/api';
  // Or use environment variables
  // static const String baseUrl = String.fromEnvironment(
  //   'API_URL',
  //   defaultValue: 'https://your-api.onrender.com/api',
  // );
}
```

### Step 3: Deploy on Vercel

#### Method A: Via Vercel CLI (Recommended)

1. **Install Vercel CLI**

   ```bash
   npm i -g vercel
   ```

2. **Login to Vercel**

   ```bash
   vercel login
   ```

3. **Deploy**
   ```bash
   cd flutter_codelab/build/web
   vercel --prod
   ```

#### Method B: Via Vercel Website

1. **Register Account**

   - Visit https://vercel.com
   - Sign in with GitHub account

2. **Create New Project**

   - Click "Add New..." → "Project"
   - Import GitHub repository (optional)
   - Or directly upload folder

3. **Configure Project**

   - **Framework Preset**: Other
   - **Root Directory**: `flutter_codelab/build/web`
   - **Build Command**: (Leave empty, already built)
   - **Output Directory**: `.` (current directory)

4. **Environment Variables** (if needed)

   ```
   API_URL=https://your-api.onrender.com/api
   ```

5. **Deploy**
   - Click "Deploy"
   - Wait for deployment to complete
   - You'll get a URL, e.g.: `https://kalmnest.vercel.app`

### Step 4: Configure Auto Deployment (Optional)

Create `vercel.json` in project root:

```json
{
  "buildCommand": "cd flutter_codelab && flutter build web --release",
  "outputDirectory": "flutter_codelab/build/web",
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ]
}
```

---

## 🔄 Solution 2: Railway.app (Full-Stack Deployment)

Railway can deploy both frontend and backend, but has limited free tier.

### Deploy Backend to Railway

1. **Register Account**

   - Visit https://railway.app
   - Sign in with GitHub

2. **Create New Project**

   - "New Project" → "Deploy from GitHub repo"
   - Select `backend_services` directory

3. **Configure Service**

   - Railway will auto-detect Laravel
   - Add environment variables (same as Render)
   - Set start command:
     ```bash
     php -S 0.0.0.0:$PORT -t public
     ```

4. **Deploy**
   - Railway will auto-deploy
   - Get URL

### Deploy Frontend to Railway

1. **Add New Service**

   - In the same project "New" → "Static Site"
   - Select `flutter_codelab/build/web` directory

2. **Configure**
   - Deploy static files directly
   - Set environment variables (API URL)

---

## 🔧 Solution 3: Fly.io (For Experienced Developers)

Fly.io provides better performance and fewer restrictions.

### Deployment Steps

1. **Install Fly CLI**

   ```bash
   powershell -Command "iwr https://fly.io/install.ps1 -useb | iex"
   ```

2. **Login**

   ```bash
   fly auth login
   ```

3. **Initialize Project**

   ```bash
   cd backend_services
   fly launch
   ```

4. **Configure `fly.toml`**

   ```toml
   app = "kalmnest-api"
   primary_region = "sin"  # Choose region closest to you

   [build]
     builder = "paketobuildpacks/builder:base"

   [http_service]
     internal_port = 8080
     force_https = true
     auto_stop_machines = true
     auto_start_machines = true
     min_machines_running = 0

   [[services]]
     protocol = "tcp"
     internal_port = 8080
   ```

5. **Deploy**
   ```bash
   fly deploy
   ```

---

## ⚙️ Important Configuration Checklist

### Backend Configuration

- [ ] ✅ `.env` file configured correctly
- [ ] ✅ `APP_KEY` generated
- [ ] ✅ `APP_DEBUG=false` (production environment)
- [ ] ✅ Database connection information correct
- [ ] ✅ CORS configuration allows frontend domain
- [ ] ✅ `storage/` directory writable (may need configuration)
- [ ] ✅ Database migrations run

### Frontend Configuration

- [ ] ✅ API address updated to backend URL
- [ ] ✅ CORS configuration correct
- [ ] ✅ Build successful without errors
- [ ] ✅ Static resource paths correct

---

## 🔒 Security Recommendations

1. **Environment Variables**

   - ✅ Never commit `.env` file to Git
   - ✅ Use platform's environment variable feature
   - ✅ Regularly rotate keys and passwords

2. **Database**

   - ✅ Use strong passwords
   - ✅ Limit database access IP (if possible)
   - ✅ Regularly backup database

3. **HTTPS**

   - ✅ All platforms provide free SSL certificates
   - ✅ Ensure all API calls use HTTPS

4. **CORS**
   - ✅ Only allow necessary domains
   - ✅ Don't use `*` as allowed origin

---

## 🐛 Common Issues Troubleshooting

### Issue 1: Backend Cannot Connect to Database

**Solution**:

- Check if database host address is correct
- Confirm database allows remote connections
- Check firewall rules
- Verify username and password

### Issue 2: CORS Errors

**Solution**:

- Update `allowed_origins` in `config/cors.php`
- Ensure frontend URL is in allowed list
- Check `SANCTUM_STATEFUL_DOMAINS` configuration

### Issue 3: Static Files 404

**Solution**:

- Check `public/` directory permissions
- Ensure `.htaccess` file exists
- Verify file path configuration

### Issue 4: Application Sleeping (Render Free Tier)

**Solution**:

- Use UptimeRobot (free) to regularly ping your application
- Or upgrade to paid plan
- Or use Railway/Fly.io (better free tier)

### Issue 5: Build Failure

**Solution**:

- Check build logs
- Ensure all dependencies are in `composer.json`
- Verify PHP version compatibility
- Check if environment variables are set correctly

---

## 📊 Platform Comparison

| Platform    | Free Tier Limits               | Advantages                 | Disadvantages                   |
| ----------- | ------------------------------ | -------------------------- | ------------------------------- |
| **Render**  | Sleeps after 15 min inactivity | Simple, easy, auto-deploy  | Slow first access after sleep   |
| **Railway** | $5 free credit/month           | Fast, supports full-stack  | Limited free credit             |
| **Vercel**  | 100GB bandwidth/month          | Extremely fast, global CDN | Only supports static/Serverless |
| **Fly.io**  | 3 shared CPU, 256MB RAM        | Good performance, no sleep | More complex configuration      |

---

## 🎯 Recommended Solutions Summary

### Best Free Solution (Recommended)

1. **Backend**: Render.com

   - Free, simple
   - Auto-deployment
   - Supports Laravel

2. **Frontend**: Vercel
   - Free, extremely fast
   - Global CDN
   - Auto-deployment

### Budget Solution ($5/month)

1. **Full-Stack**: Railway.app
   - One platform manages everything
   - Faster deployment
   - No sleep

---

## 📝 Post-Deployment Checklist

- [ ] Backend API accessible (`/api/health`)
- [ ] Frontend loads correctly
- [ ] Frontend can call backend API
- [ ] Database connection normal
- [ ] User registration/login works
- [ ] Static resources load correctly
- [ ] HTTPS works correctly
- [ ] CORS configuration correct

---

## 🔗 Useful Links

- [Render Documentation](https://render.com/docs)
- [Vercel Documentation](https://vercel.com/docs)
- [Railway Documentation](https://docs.railway.app)
- [Fly.io Documentation](https://fly.io/docs)
- [Laravel Deployment Documentation](https://laravel.com/docs/deployment)
- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)

---

## 💡 Next Steps

1. ✅ Deploy backend to Render
2. ✅ Deploy frontend to Vercel
3. ✅ Test all functionality
4. ✅ Configure custom domain (optional)
5. ✅ Set up monitoring and logging (optional)

**Good luck with your deployment!** 🚀
