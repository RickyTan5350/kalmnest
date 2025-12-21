# Configure Laravel Herd for kalmnest.test

This guide will help you configure Laravel Herd to use `kalmnest.test` instead of `backend_services.test`.

## Method 1: Using Herd GUI (Recommended)

### Step 1: Open Laravel Herd
1. Open the **Laravel Herd** application from your Windows Start menu or system tray
2. Click on the **Sites** tab in the Herd interface

### Step 2: Add or Edit Site
**Option A: If `backend_services.test` already exists:**
1. Find `backend_services` in your sites list
2. Right-click on it and select **"Edit"** or click the **Edit** button
3. Change the **Site Name** from `backend_services` to `kalmnest`
4. Click **Save** or **Apply**

**Option B: If you need to add a new site:**
1. Click the **"+"** or **"Add Site"** button
2. Browse to or enter the path: `C:\Users\junyi\Downloads\kalmnest\kalmnest\backend_services`
3. Set the **Site Name** to: `kalmnest`
4. Click **Save** or **Apply**

### Step 3: Verify the Site
1. The site should now appear as `kalmnest` in your sites list
2. The URL should be `https://kalmnest.test`
3. Click on the site to open it in your browser, or manually visit `https://kalmnest.test`

### Step 4: Secure the Site (HTTPS)
1. In Herd, make sure the site has a **lock icon** (indicating HTTPS is enabled)
2. If not secured, right-click the site and select **"Secure"** or click the **Secure** button
3. Herd will automatically generate SSL certificates for `kalmnest.test`

## Method 2: Using Herd Command Line (Alternative)

If you prefer using the command line, you can use Herd's CLI commands:

### Step 1: Open PowerShell or Command Prompt
Navigate to your project directory:
```powershell
cd C:\Users\junyi\Downloads\kalmnest\kalmnest
```

### Step 2: Link the Site
```powershell
# Link the backend_services directory with the name "kalmnest"
herd link kalmnest backend_services
```

Or if you're already in the backend_services directory:
```powershell
cd backend_services
herd link kalmnest
```

### Step 3: Secure the Site
```powershell
herd secure kalmnest
```

### Step 4: Verify
```powershell
# List all sites
herd links

# Test the site
herd open kalmnest
```

## Method 3: Manual Configuration (Advanced)

If the above methods don't work, you can manually configure it:

### Step 1: Find Herd Configuration Directory
Herd stores site configurations in:
```
C:\Users\<YourUsername>\AppData\Roaming\Herd\config\valet\Sites
```

### Step 2: Create or Edit Configuration
1. Navigate to the Sites directory
2. If `backend_services.test` exists, rename the folder to `kalmnest.test`
3. Or create a new symbolic link:
   ```powershell
   # Run PowerShell as Administrator
   New-Item -ItemType SymbolicLink -Path "C:\Users\junyi\AppData\Roaming\Herd\config\valet\Sites\kalmnest.test" -Target "C:\Users\junyi\Downloads\kalmnest\kalmnest\backend_services"
   ```

### Step 3: Restart Herd
1. Right-click Herd in system tray → **Restart**
2. Or use command: `herd restart`

## Verification Steps

### 1. Test the URL
Open your browser and visit:
- `https://kalmnest.test` - Should show Laravel welcome page or your app
- `https://kalmnest.test/api` - Should show API routes (may require authentication)

### 2. Check Herd Status
In Herd GUI, verify:
- ✅ Site `kalmnest` is listed
- ✅ Status shows as "Running" or "Active"
- ✅ HTTPS is enabled (lock icon)

### 3. Test API Endpoint
Test from Flutter app or use curl:
```powershell
curl https://kalmnest.test/api
```

### 4. Check Laravel .env
Make sure your `backend_services/.env` file has:
```env
APP_URL=https://kalmnest.test
```

## Troubleshooting

### Issue: Site not accessible
**Solution:**
1. Restart Herd: Right-click system tray → Restart
2. Clear DNS cache: `ipconfig /flushdns` (run in PowerShell as Admin)
3. Check if site is secured: `herd secure kalmnest`

### Issue: SSL Certificate Error
**Solution:**
1. Unsecure and re-secure: `herd unsecure kalmnest` then `herd secure kalmnest`
2. Restart Herd
3. Clear browser cache

### Issue: 404 Not Found
**Solution:**
1. Verify the site path is correct in Herd
2. Check that `public/index.php` exists in `backend_services/public/`
3. Ensure Laravel routes are properly configured

### Issue: Multiple Sites Conflict
**Solution:**
1. Remove old `backend_services` site from Herd
2. Keep only `kalmnest` site
3. Restart Herd

## After Configuration

Once `kalmnest.test` is working:

1. ✅ **Update Laravel .env** (if needed):
   ```env
   APP_URL=https://kalmnest.test
   ```

2. ✅ **Clear Laravel config cache**:
   ```powershell
   cd backend_services
   php artisan config:clear
   ```

3. ✅ **Test from Flutter app** - The app should now connect to `https://kalmnest.test/api`

4. ✅ **Remove old site** (optional):
   - In Herd, remove `backend_services` site if it still exists
   - Or run: `herd unlink backend_services`

## Quick Reference Commands

```powershell
# Link site
herd link kalmnest backend_services

# Secure site (HTTPS)
herd secure kalmnest

# Unsecure site
herd unsecure kalmnest

# List all sites
herd links

# Open site in browser
herd open kalmnest

# Restart Herd
herd restart

# Check Herd status
herd status
```

