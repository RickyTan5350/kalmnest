# 🚀 Complete Deployment Documentation

## 📋 Table of Contents

1. [Deployment Overview](#deployment-overview)
2. [What Was Done](#what-was-done)
3. [Code Changes Made](#code-changes-made)
4. [Database Connection Setup](#database-connection-setup)
5. [Working with Team Repository](#working-with-team-repository)
6. [Potential Problems & Solutions](#potential-problems--solutions)
7. [Team Member Instructions](#team-member-instructions)
8. [Additional Notes](#additional-notes)

---

## 1. Deployment Overview

### Architecture

```
┌─────────────────────┐
│  Flutter Web        │  → Deployed to Vercel
│  (Frontend)         │     https://kalmnest-frontend.vercel.app
└──────────┬──────────┘
           │ API Calls
           ▼
┌─────────────────────┐
│  Laravel API        │  → Deployed to Render.com
│  (Backend)          │     https://kalmnest-api.onrender.com
└──────────┬──────────┘
           │ Database Connection
           ▼
┌─────────────────────┐
│  MySQL Database     │  → Your free MySQL server
└─────────────────────┘
```

### Deployment Platforms

- **Backend**: Render.com (Free tier with Docker)
- **Frontend**: Vercel (Free tier)
- **Database**: Free MySQL server (already configured)

### URLs

- **Backend API**: `https://kalmnest-api.onrender.com`
- **Frontend App**: `https://kalmnest-frontend.vercel.app`
- **Repository**: `https://github.com/RickyTan5350/kalmnest` (branch: `class-module-main`)

---

## 2. What Was Done

### 2.1 Backend Deployment (Laravel to Render.com)

#### Step 1: Created Docker Configuration
- **File**: `backend_services/Dockerfile`
  - Uses PHP 8.4 with Apache
  - Installs required PHP extensions (pdo_mysql, mbstring, etc.)
  - Handles Composer dependencies with fallback mechanism
  - Sets up proper permissions for Laravel storage

- **File**: `backend_services/docker/apache-config.conf`
  - Apache configuration for Laravel
  - Enables mod_rewrite for routing
  - Sets document root to `public/`

- **File**: `backend_services/docker/start.sh`
  - Runtime startup script
  - Clears and caches Laravel config at runtime (when env vars are available)
  - Starts Apache server

#### Step 2: Created Render Configuration
- **File**: `backend_services/render.yaml`
  - Defines web service configuration
  - Sets Docker as runtime
  - Configures build and start commands

- **File**: `backend_services/Procfile`
  - Alternative deployment method (not used, but available)

#### Step 3: Fixed Production Issues

**Issue 1: Telescope Not Found**
- **Problem**: `TelescopeServiceProvider` was registered but Telescope is a dev dependency
- **Solution**: Modified `bootstrap/providers.php` to conditionally register Telescope only if installed or in local environment

**Issue 2: Config Caching Timing**
- **Problem**: Config was cached during Docker build, but environment variables aren't available yet
- **Solution**: Moved `config:cache` to runtime startup script

**Issue 3: Role Model Case Sensitivity**
- **Problem**: `Class "App\Models\Role" not found` on Linux (case-sensitive)
- **Solution**: 
  - Renamed `role.php` → `Role.php`
  - Changed class name from `role` → `Role`
  - Added `use App\Models\Role;` in `User.php`

#### Step 4: CORS Configuration
- **File**: `backend_services/config/cors.php`
  - Configured to allow frontend domain
  - Supports Vercel, Netlify, Railway patterns
  - Uses environment variable `FRONTEND_URL`

#### Step 5: Composer Dependencies
- **File**: `backend_services/composer.json`
  - Added explicit `php-http/discovery` dependency (required by google-gemini-php/client)
  - Updated Dockerfile to handle outdated `composer.lock` files

### 2.2 Frontend Deployment (Flutter Web to Vercel)

#### Step 1: Updated API Configuration
- **File**: `flutter_codelab/lib/constants/api_constants.dart`
  - Updated production API URL to `https://kalmnest-api.onrender.com/api`
  - Updated domain URL to `https://kalmnest-api.onrender.com`

#### Step 2: Built Flutter Web
- Built using: `flutter build web --release`
- Output directory: `flutter_codelab/build/web/`

#### Step 3: Deployed to Vercel
- Used Vercel CLI: `npx vercel --prod`
- Project name: `kalmnest-frontend`
- Automatically configured for static file hosting

### 2.3 Environment Variables Configuration

#### Backend (Render.com)
Configured the following environment variables:
- `APP_KEY` - Laravel application encryption key
- `APP_ENV=production`
- `APP_DEBUG=false`
- `APP_URL=https://kalmnest-api.onrender.com`
- `DB_CONNECTION=mysql`
- `DB_HOST` - Your MySQL host
- `DB_DATABASE` - Database name
- `DB_USERNAME` - Database username
- `DB_PASSWORD` - Database password
- `FRONTEND_URL=https://kalmnest-frontend.vercel.app`
- `SANCTUM_STATEFUL_DOMAINS=kalmnest-frontend.vercel.app`

---

## 3. Code Changes Made

### 3.1 Backend Changes

#### New Files Created

1. **`backend_services/Dockerfile`**
   ```dockerfile
   FROM php:8.4-apache
   # ... (see file for full content)
   ```
   - Docker image for Laravel deployment
   - Handles Composer dependencies with fallback
   - Sets up Apache and PHP extensions

2. **`backend_services/docker/apache-config.conf`**
   - Apache virtual host configuration
   - Routes all requests to Laravel's `public/index.php`

3. **`backend_services/docker/start.sh`**
   ```bash
   #!/bin/bash
   php artisan config:clear
   php artisan cache:clear
   php artisan config:cache
   apache2-foreground
   ```
   - Runtime startup script
   - Caches config after environment variables are loaded

4. **`backend_services/render.yaml`**
   ```yaml
   services:
     - type: web
       name: kalmnest-api
       runtime: docker
       # ... (see file for full content)
   ```
   - Render.com service configuration

5. **`backend_services/Procfile`**
   ```
   web: vendor/bin/heroku-php-apache2 public/
   ```
   - Alternative deployment method (not used)

6. **`backend_services/config/cors.php`**
   - CORS configuration for API
   - Allows frontend domain

#### Modified Files

1. **`backend_services/bootstrap/providers.php`**
   ```php
   // Before: Always registered TelescopeServiceProvider
   // After: Conditionally registers only if Telescope is installed
   if (app()->environment('local') || class_exists(\Laravel\Telescope\TelescopeApplicationServiceProvider::class)) {
       $providers[] = App\Providers\TelescopeServiceProvider::class;
   }
   ```
   - **Reason**: Telescope is a dev dependency, not available in production

2. **`backend_services/app/Models/role.php` → `Role.php`**
   ```php
   // Before: class role extends Model
   // After: class Role extends Model
   ```
   - **Reason**: Linux systems are case-sensitive, code uses `Role::class`

3. **`backend_services/app/Models/User.php`**
   ```php
   // Added:
   use App\Models\Role;
   
   // In role() method:
   return $this->belongsTo(Role::class, 'role_id', 'role_id');
   ```
   - **Reason**: Explicit import for Role model

4. **`backend_services/composer.json`**
   ```json
   // Added:
   "php-http/discovery": "^1.19"
   ```
   - **Reason**: Required by google-gemini-php/client but not explicitly listed

5. **`backend_services/Dockerfile`** (Composer install logic)
   ```dockerfile
   // Added fallback mechanism:
   RUN composer install ... || \
       (composer update ... && composer install ...)
   ```
   - **Reason**: Handles outdated composer.lock files

### 3.2 Frontend Changes

#### Modified Files

1. **`flutter_codelab/lib/constants/api_constants.dart`**
   ```dart
   // Before:
   if (kIsWeb) {
       return 'https://kalmnest.test/api';
   }
   
   // After:
   if (kIsWeb) {
       return 'https://kalmnest-api.onrender.com/api';
   }
   ```
   - **Reason**: Point to production API URL

---

## 4. Database Connection Setup

### 4.1 Required Environment Variables

In Render.com Dashboard → Your Service → Environment:

```env
DB_CONNECTION=mysql
DB_HOST=your-mysql-host.com
DB_PORT=3306
DB_DATABASE=your_database_name
DB_USERNAME=your_username
DB_PASSWORD=your_password
```

### 4.2 Database Connection Details

The database connection is configured in `backend_services/config/database.php`:

```php
'mysql' => [
    'driver' => 'mysql',
    'host' => env('DB_HOST', '127.0.0.1'),
    'port' => env('DB_PORT', '3306'),
    'database' => env('DB_DATABASE', 'laravel'),
    'username' => env('DB_USERNAME', 'root'),
    'password' => env('DB_PASSWORD', ''),
    // ... SSL configuration (optional)
],
```

### 4.3 SSL Certificate (If Required)

If your MySQL server requires SSL:

1. **Option 1: Disable SSL** (if not required)
   - Leave `MYSQL_ATTR_SSL_CA` empty in environment variables

2. **Option 2: Use SSL Certificate**
   - Add certificate file to Docker image
   - Set `MYSQL_ATTR_SSL_CA` environment variable to certificate path

### 4.4 Testing Database Connection

In Render Shell:
```bash
php artisan tinker
DB::connection()->getPdo();
# Should output: PDO connection object
```

### 4.5 Common Database Issues

**Issue**: Connection refused
- **Check**: Database host, port, username, password
- **Check**: Database server allows remote connections
- **Check**: Firewall/whitelist settings

**Issue**: SSL certificate error
- **Solution**: Set `MYSQL_ATTR_SSL_CA` to empty or provide certificate

---

## 5. Working with Team Repository

### 5.1 Current Setup

- **Repository**: `RickyTan5350/kalmnest`
- **Branch**: `class-module-main`
- **Deployment**: Automatic via Render.com (monitors GitHub)

### 5.2 If Other Members Make Changes

#### Scenario 1: Member Pushes to Same Branch

1. **Render.com automatically redeploys** when changes are pushed to `class-module-main`
2. **No action needed** - deployment is automatic

#### Scenario 2: Member Creates New Branch

1. **Option A: Merge to main branch**
   ```bash
   git checkout class-module-main
   git merge member-branch-name
   git push origin class-module-main
   ```
   - Render will automatically redeploy

2. **Option B: Update Render to use new branch**
   - Go to Render Dashboard
   - Select your service
   - Settings → Branch → Change to new branch
   - Save and redeploy

#### Scenario 3: Member Makes Code Changes

**If changes affect deployment:**

1. **Docker-related changes**
   - Update `Dockerfile` if needed
   - Test locally: `docker build -t test .`

2. **Environment variable changes**
   - Add new variables in Render Dashboard
   - Update documentation

3. **Database changes**
   - Run migrations: `php artisan migrate`
   - Update seeders if needed

4. **Dependency changes**
   - Update `composer.json` or `package.json`
   - Push changes - Render will rebuild

**If changes don't affect deployment:**
- Just push to GitHub - Render handles the rest

### 5.3 Deployment Workflow for Team

```
1. Member makes code changes
   ↓
2. Member commits and pushes to GitHub
   ↓
3. Render.com detects changes (webhook)
   ↓
4. Render.com rebuilds Docker image
   ↓
5. Render.com redeploys service
   ↓
6. Service is live with new changes
```

**Note**: Render free tier may take 5-10 minutes to deploy

### 5.4 Frontend Updates

For Flutter Web frontend:

1. **Member makes changes**
2. **Rebuild Flutter Web**:
   ```bash
   cd flutter_codelab
   flutter build web --release
   ```
3. **Deploy to Vercel**:
   ```bash
   cd build/web
   npx vercel --prod
   ```

**Or** set up automatic deployment:
- Connect Vercel to GitHub
- Configure build command: `flutter build web --release`
- Output directory: `flutter_codelab/build/web`

**Note**: Vercel doesn't have Flutter, so automatic deployment may fail. Manual deployment is recommended.

---

## 6. Potential Problems & Solutions

### 6.1 Backend Issues

#### Problem 1: 500 Internal Server Error

**Symptoms**: API returns 500 error

**Common Causes**:
1. Missing `APP_KEY`
2. Database connection failed
3. Missing environment variables
4. Class not found (case sensitivity)

**Solutions**:
1. Check Render logs for specific error
2. Verify all environment variables are set
3. Test database connection
4. Clear Laravel cache:
   ```bash
   php artisan config:clear
   php artisan cache:clear
   ```

#### Problem 2: Class Not Found

**Symptoms**: `Class "App\Models\X" not found`

**Cause**: Case sensitivity on Linux

**Solution**: Ensure class names match file names exactly (case-sensitive)

#### Problem 3: Telescope Error

**Symptoms**: `TelescopeApplicationServiceProvider not found`

**Solution**: Already fixed - Telescope is conditionally registered

#### Problem 4: Composer Install Fails

**Symptoms**: Build fails during `composer install`

**Solution**: Dockerfile has fallback mechanism - will try `composer update` if install fails

#### Problem 5: Config Cache Issues

**Symptoms**: Old configuration values persist

**Solution**: Startup script clears and recaches config at runtime

### 6.2 Frontend Issues

#### Problem 1: CORS Error

**Symptoms**: `Access to fetch blocked by CORS policy`

**Solutions**:
1. Check `FRONTEND_URL` in Render environment variables
2. Verify frontend URL in `config/cors.php`
3. Restart backend service

#### Problem 2: API Connection Failed

**Symptoms**: Network error when calling API

**Solutions**:
1. Check API URL in `api_constants.dart`
2. Verify backend is running
3. Check browser console for errors

#### Problem 3: Blank Page

**Solutions**:
1. Check browser console for errors
2. Verify all files uploaded correctly
3. Check Vercel deployment logs

### 6.3 Database Issues

#### Problem 1: Connection Refused

**Solutions**:
1. Verify database credentials
2. Check database server is running
3. Verify remote connections are allowed
4. Check firewall/whitelist settings

#### Problem 2: SSL Certificate Error

**Solutions**:
1. Set `MYSQL_ATTR_SSL_CA` to empty if SSL not required
2. Or provide correct certificate path

### 6.4 Deployment Issues

#### Problem 1: Render Build Fails

**Solutions**:
1. Check build logs in Render Dashboard
2. Verify Dockerfile is correct
3. Check for syntax errors
4. Ensure all files are committed to GitHub

#### Problem 2: Vercel Build Fails (Flutter)

**Solution**: Vercel doesn't support Flutter - deploy pre-built files instead

---

## 7. Team Member Instructions

### 7.1 For Members Making Code Changes

#### What You Need to Do:

1. **Make your code changes** as usual
2. **Test locally** before pushing
3. **Commit and push** to GitHub:
   ```bash
   git add .
   git commit -m "Your change description"
   git push origin class-module-main
   ```
4. **That's it!** Render will automatically deploy

#### What You DON'T Need to Do:

- ❌ Don't modify Dockerfile (unless you know what you're doing)
- ❌ Don't modify Render configuration
- ❌ Don't modify environment variables in Render (contact deployer)
- ❌ Don't rebuild Docker images manually
- ❌ Don't manually trigger deployments

#### Special Cases:

**If you add new environment variables:**
1. Document them in this file
2. Notify the deployer to add them in Render Dashboard

**If you add new Composer dependencies:**
1. Update `composer.json`
2. Push changes - Render will handle installation

**If you modify database schema:**
1. Create migration: `php artisan make:migration your_migration`
2. Push migration file
3. Migration runs automatically on deployment (if configured)

**If you modify Flutter frontend:**
1. Make changes
2. Rebuild: `flutter build web --release`
3. Deploy: `cd build/web && npx vercel --prod`
4. Or notify deployer to handle deployment

### 7.2 For Members Who Just Need to Give Code

#### Minimal Process:

1. **Write your code**
2. **Commit and push**:
   ```bash
   git add .
   git commit -m "Feature: Your feature description"
   git push origin class-module-main
   ```
3. **Done!** Deployment is automatic

#### What Happens Automatically:

- ✅ Code is pulled from GitHub
- ✅ Docker image is rebuilt
- ✅ Dependencies are installed
- ✅ Service is redeployed
- ✅ New code is live (in 5-10 minutes)

#### When to Contact Deployer:

- If you need new environment variables
- If deployment fails (check Render logs first)
- If you need database changes
- If you need frontend deployment

### 7.3 Communication Protocol

**Before making major changes:**
- Notify team about:
  - New environment variables needed
  - Database schema changes
  - New dependencies
  - Breaking changes

**After deployment fails:**
1. Check Render logs first
2. Document the error
3. Contact deployer with:
   - Error message
   - What you changed
   - Render log snippet

---

## 8. Additional Notes

### 8.1 Render.com Free Tier Limitations

- **Spins down after inactivity**: First request after inactivity may take 50+ seconds
- **Solution**: Use UptimeRobot or similar to ping your service regularly

- **Build time limits**: Free tier has build time limits
- **Solution**: Optimize Dockerfile and dependencies

- **Resource limits**: Limited CPU and memory
- **Solution**: Optimize code and database queries

### 8.2 Vercel Free Tier

- **No Flutter support**: Must build locally and upload
- **Automatic deployments**: Can connect to GitHub (but Flutter build will fail)
- **Solution**: Use manual deployment with CLI

### 8.3 Security Considerations

1. **Environment Variables**: Never commit `.env` file
2. **API Keys**: Store in Render environment variables
3. **Database Credentials**: Use strong passwords
4. **CORS**: Only allow trusted domains

### 8.4 Monitoring & Logs

**Backend Logs**:
- Render Dashboard → Your Service → Logs
- Real-time log streaming available

**Frontend Logs**:
- Vercel Dashboard → Your Project → Deployments → View Logs
- Browser console for client-side errors

### 8.5 Backup & Recovery

**Database**:
- Regular backups recommended
- Export database periodically

**Code**:
- All code in GitHub (backed up)
- Tag important releases

### 8.6 Performance Optimization

**Backend**:
- Enable Laravel caching
- Optimize database queries
- Use Redis for sessions (if needed)

**Frontend**:
- Flutter Web is already optimized
- Consider CDN for static assets

### 8.7 Future Improvements

**Potential Enhancements**:
1. Set up CI/CD pipeline
2. Add automated testing
3. Implement staging environment
4. Add monitoring/alerting
5. Set up database backups
6. Implement caching layer

### 8.8 Important Files Reference

**Backend Deployment Files**:
- `backend_services/Dockerfile` - Docker configuration
- `backend_services/docker/apache-config.conf` - Apache config
- `backend_services/docker/start.sh` - Startup script
- `backend_services/render.yaml` - Render service config
- `backend_services/config/cors.php` - CORS configuration

**Frontend Deployment**:
- `flutter_codelab/lib/constants/api_constants.dart` - API URL configuration
- `flutter_codelab/build/web/` - Built files (deploy this)

**Documentation**:
- `COMPLETE_DEPLOYMENT_DOCUMENTATION.md` - This file
- `DEPLOYMENT_GUIDE.md` - Detailed deployment guide
- `DEPLOYMENT_QUICK_START.md` - Quick reference
- `RENDER_DOCKER_SETUP.md` - Docker setup details

---

## 9. Quick Reference Commands

### Backend

```bash
# Local testing
cd backend_services
php artisan serve

# Check logs (Render Shell)
tail -f storage/logs/laravel.log

# Clear cache (Render Shell)
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear

# Test database (Render Shell)
php artisan tinker
DB::connection()->getPdo();
```

### Frontend

```bash
# Build Flutter Web
cd flutter_codelab
flutter build web --release

# Deploy to Vercel
cd build/web
npx vercel --prod

# Check Vercel deployment
vercel ls
```

### Git

```bash
# Standard workflow
git add .
git commit -m "Description"
git push origin class-module-main
```

---

## 10. Support & Troubleshooting

### Getting Help

1. **Check logs first**: Render Dashboard → Logs
2. **Check this documentation**: Search for your issue
3. **Check Laravel logs**: `storage/logs/laravel.log`
4. **Contact deployer**: With error details and logs

### Common Error Messages

- `Class not found` → Case sensitivity issue
- `500 Internal Server Error` → Check logs for specific error
- `CORS error` → Check FRONTEND_URL environment variable
- `Database connection failed` → Check DB credentials
- `Telescope not found` → Already fixed, shouldn't happen

---

## 📝 Document Version

- **Created**: January 2026
- **Last Updated**: January 2026
- **Version**: 1.0
- **Maintained By**: Deployment Team

---

## ✅ Deployment Checklist

- [x] Backend deployed to Render.com
- [x] Frontend deployed to Vercel
- [x] Database connected
- [x] Environment variables configured
- [x] CORS configured
- [x] All errors fixed
- [x] Documentation created
- [x] Team instructions provided

---

**🎉 Deployment Complete!**

Your application is now live and ready for use. All team members can push code changes, and deployment will happen automatically.

