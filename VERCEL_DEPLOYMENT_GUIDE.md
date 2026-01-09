# Vercel Deployment Guide - Flutter Web Frontend

This guide will help you deploy the KalmNest Flutter Web frontend to Vercel.

## 📋 Prerequisites

1. ✅ GitHub repository created and contains code
2. ✅ Vercel account created ([https://vercel.com](https://vercel.com))
3. ✅ Backend API deployed (e.g., Laravel backend on Render)
4. ✅ Flutter SDK installed (for local testing builds)

## 🚀 Quick Deployment Steps

### Method 1: Via Vercel Dashboard (Recommended)

#### Step 1: Create New Project

1. Log in to Vercel Dashboard: [https://vercel.com/dashboard](https://vercel.com/dashboard)
2. Click **"New Project"** or **"Add New..." → "Project"**
3. Select **"Import Git Repository"**
4. Select or authorize access to GitHub repository: **`RickyTan5350/kalmnest`**
5. Click **"Import"**

#### Step 2: Configure Project Settings

On the project configuration page, fill in the following information:

**General Settings:**

- **Project Name**: `kalmnest` (or your preferred name)
- **Framework Preset**: **Other** or **Other (No Framework)**
- **Root Directory**: `./` (project root directory)

**Build & Development Settings:**

- **Build Command**:

  ```bash
  cd flutter_codelab && flutter pub get && flutter build web --release --base-href /
  ```

  Or use the script in package.json:

  ```bash
  npm run vercel-build
  ```

- **Output Directory**:

  ```
  flutter_codelab/build/web
  ```

- **Install Command**:

  ```bash
  cd flutter_codelab && flutter pub get
  ```

  Or:

  ```bash
  npm install
  ```

#### Step 3: Configure Environment Variables

In the **"Environment Variables"** section, add the following variable:

**Required Environment Variable:**

```
CUSTOM_BASE_URL=https://your-backend-url.onrender.com
```

**Notes:**

- `CUSTOM_BASE_URL`: Your backend API URL (e.g., `https://kalmnest-api.onrender.com`)
- This variable will override the default local development URL (`kalmnest.test`)
- Ensure the URL does not include a trailing slash

**Environment Variable Configuration Example:**

| Key               | Value                               | Environment                      |
| ----------------- | ----------------------------------- | -------------------------------- |
| `CUSTOM_BASE_URL` | `https://kalmnest-api.onrender.com` | Production, Preview, Development |

#### Step 4: Deploy

1. Click the **"Deploy"** button
2. Wait for the build to complete (first build may take 5-10 minutes)
3. After successful build, you will receive a deployment URL (e.g., `https://kalmnest.vercel.app`)

### Method 2: Using Vercel CLI

#### Step 1: Install Vercel CLI

```bash
npm install -g vercel
```

#### Step 2: Login to Vercel

```bash
vercel login
```

#### Step 3: Deploy from Project Root

```bash
vercel
```

Follow the prompts:

- Set up and deploy? → **Y**
- Which scope? → Select your account
- Link to existing project? → **N** (first deployment)
- What's your project's name? → **kalmnest**
- In which directory is your code located? → **./**

#### Step 4: Set Environment Variables

```bash
vercel env add CUSTOM_BASE_URL
```

Enter value: `https://your-backend-url.onrender.com`

#### Step 5: Production Deployment

```bash
vercel --prod
```

## ⚙️ Configuration Files

### vercel.json

The `vercel.json` configuration file created in the project root contains:

- **buildCommand**: Flutter Web build command
- **outputDirectory**: Build output directory
- **rewrites**: SPA (Single Page Application) route rewrite rules
- **headers**: Cache control headers

### package.json

The `package.json` created in the project root contains:

- **vercel-build**: Vercel build script
- **build**: Standard build script
- **install**: Dependency installation script

## 🔧 Environment Variables Configuration

### Required Environment Variable

1. **CUSTOM_BASE_URL**
   - **Description**: Backend API base URL
   - **Format**: `https://your-backend-url.onrender.com` (no trailing slash)
   - **Example**: `https://kalmnest-api.onrender.com`
   - **Purpose**: Flutter app connects to backend API through this URL

### Optional Environment Variables

If you need different dev/production environments:

- **Development**: `https://dev-api.example.com`
- **Preview**: `https://staging-api.example.com`
- **Production**: `https://api.example.com`

Set these separately for each environment in Vercel Dashboard.

## 📝 Detailed Configuration Steps (Vercel Dashboard)

### 1. Project Configuration

In **"Settings" → "General"**:

- **Project Name**: `kalmnest`
- **Framework Preset**: **Other**
- **Root Directory**: `./`
- **Build Command**: `npm run vercel-build` or
  ```
  cd flutter_codelab && flutter pub get && flutter build web --release --base-href /
  ```
- **Output Directory**: `flutter_codelab/build/web`
- **Install Command**: `npm install` or
  ```
  cd flutter_codelab && flutter pub get
  ```

### 2. Environment Variables Settings

In **"Settings" → "Environment Variables"**, add:

```
CUSTOM_BASE_URL = https://your-backend-url.onrender.com
```

Select apply environment:

- ✅ **Production**
- ✅ **Preview**
- ✅ **Development** (Optional)

### 3. Build Configuration

In **"Settings" → "General" → "Build & Development Settings"**:

- **Node.js Version**: `18.x` or higher
- **Install Command**: `cd flutter_codelab && flutter pub get`
- **Build Command**: `cd flutter_codelab && flutter pub get && flutter build web --release --base-href /`
- **Output Directory**: `flutter_codelab/build/web`

### 4. Deployment Settings

In **"Settings" → "Deployments"**:

- **Auto-deploy from GitHub**: Enable (automatic deployment)
- **Production Branch**: `main`
- **Preview Deployments**: Enable (create preview for each PR)

## 🐛 Troubleshooting

### Issue 1: Build Failed - Flutter Not Found

**Error**: `flutter: command not found`

**Solution**:

1. Vercel uses Docker images, ensure you've selected a build environment that includes Flutter
2. Add Flutter installation step in `package.json`
3. Or use a custom build image (configure in Vercel Settings)

**Temporary Solution** - Update `package.json`:

```json
{
  "scripts": {
    "vercel-build": "echo 'Install Flutter here' && cd flutter_codelab && flutter pub get && flutter build web --release --base-href /"
  }
}
```

### Issue 2: Build Failed - Dependency Installation Failed

**Error**: `flutter pub get` failed

**Solution**:

1. Check dependency versions in `pubspec.yaml`
2. Ensure `pubspec.lock` is committed to Git
3. Clear build cache: Vercel Dashboard → Settings → General → Clear Build Cache

### Issue 3: 404 Error - Routes Not Working

**Error**: Refresh page shows 404

**Solution**:

1. Ensure `rewrites` configuration in `vercel.json` is correct
2. Check if `base-href` parameter is set correctly (should be `/`)

### Issue 4: API Request Failed - CORS Error

**Error**: CORS policy blocking requests

**Solution**:

1. Ensure backend is configured to allow CORS from Vercel domain
2. In Laravel backend's `config/cors.php`, add:
   ```php
   'allowed_origins' => [
       'https://kalmnest.vercel.app',
       'https://*.vercel.app', // Allow all Vercel preview deployments
   ],
   ```

### Issue 5: Environment Variables Not Working

**Error**: API still using default URL

**Solution**:

1. Confirm environment variable name is correct: `CUSTOM_BASE_URL`
2. Ensure variable is added to all required environments (Production, Preview)
3. Redeploy to apply new environment variables
4. Check environment variable reading logic in Flutter code

## 📊 Build Process

### Vercel Build Flow

1. **Install Dependencies** (`installCommand`):

   ```
   cd flutter_codelab && flutter pub get
   ```

   - Download all Flutter package dependencies
   - Generate necessary configuration files

2. **Build Application** (`buildCommand`):

   ```
   cd flutter_codelab && flutter pub get && flutter build web --release --base-href /
   ```

   - Compile Dart code to JavaScript
   - Optimize and compress resources
   - Generate web assets to `build/web` directory

3. **Deploy Output** (`outputDirectory`):
   ```
   flutter_codelab/build/web
   ```
   - Vercel deploys files from this directory
   - Configure routes and cache headers

## 🔄 Auto-deployment Configuration

### GitHub Integration

1. **Enable Auto-deployment**:

   - In Vercel Dashboard → Project → Settings → Git
   - Ensure GitHub repository is connected
   - Enable "Auto-deploy" option

2. **Branch Configuration**:

   - **Production**: `main` branch
   - **Preview**: All other branches and PRs

3. **Deployment Notifications**:
   - Show deployment status in GitHub PRs
   - Automatically generate preview URLs

## ✅ Post-Deployment Verification

After deployment is complete, perform the following verification steps:

### 1. Check Deployment URL

Visit deployment URL (e.g., `https://kalmnest.vercel.app`)

### 2. Test Main Features

- [ ] Page loads normally
- [ ] Login functionality works
- [ ] API requests successful (check network requests)
- [ ] Route navigation works (no 404 errors)
- [ ] Static resources load normally (images, fonts, etc.)

### 3. Check Console

Open browser developer tools (F12):

- [ ] No JavaScript errors
- [ ] No network errors (CORS, 404, etc.)
- [ ] API requests point to correct backend URL

### 4. Test Environment Variables

Verify API connection:

```javascript
// Run in browser console
fetch("https://your-backend-url.onrender.com/api/health")
  .then((r) => r.json())
  .then(console.log);
```

## 📚 Related Resources

- **Vercel Documentation**: [https://vercel.com/docs](https://vercel.com/docs)
- **Flutter Web Deployment**: [https://docs.flutter.dev/deployment/web](https://docs.flutter.dev/deployment/web)
- **Vercel CLI**: [https://vercel.com/docs/cli](https://vercel.com/docs/cli)

## 📝 Notes

1. **First Build Time**: First deployment may take 5-10 minutes, as Flutter SDK needs to be installed
2. **Build Cache**: Vercel caches builds, subsequent deployments will be faster
3. **File Size**: Ensure large files (e.g., Unity WASM files) use Git LFS or CDN
4. **Environment Variables**: Don't commit sensitive information (API keys, etc.) to code, use environment variables
5. **Custom Domain**: You can add a custom domain in Vercel Dashboard → Settings → Domains

## 🎉 Deployment Checklist

Use this checklist to ensure all steps are completed:

**Preparations:**

- [ ] GitHub repository prepared
- [ ] Backend API deployed and accessible
- [ ] Vercel account created

**Project Configuration:**

- [ ] Created `vercel.json` configuration file
- [ ] Created `package.json` file
- [ ] Configuration files committed to Git

**Vercel Settings:**

- [ ] Project imported to Vercel
- [ ] Root directory set correctly (`./`)
- [ ] Build command configured correctly
- [ ] Output directory set correctly (`flutter_codelab/build/web`)
- [ ] Environment variables configured (`CUSTOM_BASE_URL`)

**Deployment:**

- [ ] First deployment successful
- [ ] Deployment URL accessible
- [ ] Main features tested and working
- [ ] API connection normal

**Optimization:**

- [ ] Auto-deployment enabled
- [ ] Custom domain configured (optional)
- [ ] Deployment notifications set up (optional)

---

**Deployment Date**: **\*\***\_\_\_**\*\***
**Deployment URL**: https://**\*\***\_\_\_**\*\***
**Backend API URL**: https://**\*\***\_\_\_**\*\***
**Status**: ☐ Success ☐ Needs Fix
