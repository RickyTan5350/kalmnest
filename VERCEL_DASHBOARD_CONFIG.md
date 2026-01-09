# Vercel Dashboard Configuration Guide - Quick Setup

Based on the Vercel Dashboard configuration interface you provided, please fill in the following steps:

## 📝 Fill in Vercel Dashboard

### 1. Basic Information

✅ **Vercel Team**: `TAN LI JI's projects`  
✅ **Plan**: `Hobby`  
✅ **Project Name**: `kalmnest`  
✅ **GitHub Repository**: `RickyTan5350/kalmnest`  
✅ **Branch**: `main`

### 2. Framework and Directory Settings

- **Framework Preset**: Select **"Other"** or **"Other (No Framework)"**
- **Root Directory**: `./` (project root directory)

### 3. Build Configuration

⚠️ **Important**: Since Vercel doesn't include Flutter SDK by default, we provide two options:

#### Option A: Using Build Script (Recommended, but longer build time)

**Build Command**:
```bash
bash build-flutter-web.sh
```

**Or use npm script**:
```bash
npm run vercel-build
```

**Output Directory**:
```
flutter_codelab/build/web
```

**Install Command**:
```bash
npm install
```

#### Option B: Using Pre-built Files (Recommended, Faster)

If you want to use pre-built files (already built locally or via GitHub Actions):

**Build Command**:
```bash
echo "Using pre-built Flutter Web files from flutter_codelab/build/web"
```

**Output Directory**:
```
flutter_codelab/build/web
```

**Install Command**:
```bash
echo "No installation needed for pre-built files"
```

### 4. Environment Variables Configuration

In the **"Environment Variables"** section, click **"Add Environment Variable"**:

**Key**: 
```
CUSTOM_BASE_URL
```

**Value**: 
```
https://your-render-backend-url.onrender.com
```

**⚠️ Important**: 
- Replace `your-render-backend-url.onrender.com` with your actual Render backend URL
- Do NOT include trailing slash `/`
- Do NOT include `/api` suffix (code will add it automatically)
- Use HTTPS URL

**Environment**: 
- ✅ **Production** (Required)
- ✅ **Preview** (Recommended)
- ☐ **Development** (Optional)

### 5. Click "Deploy"

After configuration is complete, click the **"Deploy"** button to start deployment.

## 🎯 Recommended Complete Configuration

### If using build script (First deployment):

```
Framework Preset: Other
Root Directory: ./
Build Command: bash build-flutter-web.sh
Output Directory: flutter_codelab/build/web
Install Command: npm install
```

### If using pre-built files (Faster):

```
Framework Preset: Other
Root Directory: ./
Build Command: echo "Using pre-built files"
Output Directory: flutter_codelab/build/web
Install Command: echo "No installation needed"
```

## ⚡ Quick Deployment Option

### Fastest Method: Pre-build + Deploy

1. **Build Flutter Web locally**:
   ```bash
   cd flutter_codelab
   flutter pub get
   flutter build web --release --base-href /
   ```

2. **Commit build files to Git**:
   ```bash
   git add flutter_codelab/build/web
   git commit -m "Add pre-built Flutter Web files for Vercel deployment"
   git push origin main
   ```

3. **Configure in Vercel Dashboard**:
   - Build Command: `echo "Using pre-built files"`
   - Output Directory: `flutter_codelab/build/web`
   - Install Command: `echo "No installation needed"`

4. **Add Environment Variable**:
   - Key: `CUSTOM_BASE_URL`
   - Value: `https://your-render-backend-url.onrender.com`

5. **Click Deploy**

This method is the fastest because it doesn't need to download Flutter SDK on Vercel.

## 🔍 Verify Deployment Configuration

Before deployment, confirm the following:

- [ ] Framework Preset is set to **Other**
- [ ] Root Directory is set to `./`
- [ ] Build Command is configured
- [ ] Output Directory is set to `flutter_codelab/build/web`
- [ ] Install Command is configured
- [ ] Environment variable `CUSTOM_BASE_URL` is added
- [ ] Environment variable value is correct (your Render backend URL)

## 📞 Need More Help?

For detailed documentation, see:
- `VERCEL_SETUP_GUIDE.md` - Complete deployment guide
- `VERCEL_DEPLOYMENT_GUIDE.md` - Detailed deployment documentation
- `VERCEL_QUICK_SETUP.md` - Quick setup guide
