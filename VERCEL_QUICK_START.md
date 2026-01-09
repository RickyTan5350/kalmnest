# Vercel Quick Start Guide - Flutter Web

## 📋 Vercel Dashboard Configuration

Based on your Vercel Dashboard interface, here's what to fill in:

### Project Settings

| Field | Value |
|-------|-------|
| **Project Name** | `kalmnest` |
| **Framework Preset** | **Other** |
| **Root Directory** | `./` |
| **Build Command** | `bash build-flutter-web.sh` or `npm run vercel-build` |
| **Output Directory** | `flutter_codelab/build/web` |
| **Install Command** | `npm install` |

### Environment Variables

Click **"Environment Variables"** and add:

**Key**: `CUSTOM_BASE_URL`  
**Value**: `https://your-render-backend-url.onrender.com`  
**Environment**: ✅ Production, ✅ Preview

⚠️ **Important**:
- Replace `your-render-backend-url.onrender.com` with your actual Render backend URL
- Do NOT include trailing slash `/`
- Do NOT include `/api` suffix (code adds it automatically)
- Use HTTPS URL

### Deploy

Click **"Deploy"** and wait for the build to complete (first build may take 10-15 minutes).

---

## 🚀 Quick Deployment (Pre-built Method - Fastest)

If you want the fastest deployment, build locally first:

### 1. Build Flutter Web Locally

```bash
cd flutter_codelab
flutter pub get
flutter build web --release --base-href /
```

### 2. Commit Build Files (Optional)

If `flutter_codelab/build/web` is not in `.gitignore`:

```bash
git add flutter_codelab/build/web
git commit -m "Add pre-built Flutter Web files"
git push origin main
```

### 3. Configure Vercel Dashboard

**Build Command**: 
```
echo "Using pre-built files"
```

**Output Directory**: 
```
flutter_codelab/build/web
```

**Install Command**: 
```
echo "No installation needed"
```

### 4. Add Environment Variable

**Key**: `CUSTOM_BASE_URL`  
**Value**: `https://your-render-backend-url.onrender.com`

### 5. Deploy

Click **"Deploy"** - this will be very fast as no build is needed!

---

## 📝 Complete Configuration Reference

### Option 1: Auto Build (Using Script)

```
Framework Preset: Other
Root Directory: ./
Build Command: bash build-flutter-web.sh
Output Directory: flutter_codelab/build/web
Install Command: npm install
```

**Note**: First build will take 10-15 minutes (downloads Flutter SDK)

### Option 2: Pre-built Files (Recommended)

```
Framework Preset: Other
Root Directory: ./
Build Command: echo "Using pre-built files"
Output Directory: flutter_codelab/build/web
Install Command: echo "No installation needed"
```

**Note**: Requires pre-built files in `flutter_codelab/build/web`

---

## ✅ Checklist Before Deploying

- [ ] `vercel.json` created and committed
- [ ] `package.json` created and committed
- [ ] `build-flutter-web.sh` created and committed
- [ ] Framework Preset set to **Other**
- [ ] Root Directory set to `./`
- [ ] Build Command configured
- [ ] Output Directory set to `flutter_codelab/build/web`
- [ ] Environment variable `CUSTOM_BASE_URL` added
- [ ] Environment variable value is your Render backend URL

---

## 🔍 Verify After Deployment

1. Visit your deployment URL (e.g., `https://kalmnest.vercel.app`)
2. Open browser console (F12)
3. Check for errors
4. Test login functionality
5. Verify API requests point to correct backend URL

---

For detailed troubleshooting, see `VERCEL_DEPLOYMENT_GUIDE.md`
