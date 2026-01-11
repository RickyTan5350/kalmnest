# 🔐 Aiven MySQL SSL Configuration Guide

## ✅ Current Status

**CORS is FIXED** - You're getting 500 responses with JSON, which means:

-   ✅ Requests reach Laravel
-   ✅ Responses return to browser
-   ✅ CORS middleware is working

**The remaining issue**: MySQL SSL connection failure due to incorrect certificate path.

---

## 🚨 The Problem

Your Render environment variable has a **Windows path**:

```env
MYSQL_ATTR_SSL_CA="C:/Users/junyi/Downloads/kalmnest/kalmnest/backend_services/storage/cert/ca.pem"
```

**Why this fails:**

-   Render runs on **Linux**, not Windows
-   The path `C:/Users/...` doesn't exist on Render's container
-   Laravel can't find the certificate file
-   MySQL SSL handshake fails
-   Connection refused: `SQLSTATE[HY000] [2002] Cannot connect to MySQL using SSL`

---

## ✅ Solution: Two Options

### Option 1: Use Certificate File (Recommended for Production)

#### Step 1: Download Aiven CA Certificate

1. Go to your **Aiven Console**
2. Navigate to your MySQL service
3. Click **"Connection information"** or **"Download CA certificate"**
4. Download the `ca.pem` file

#### Step 2: Place Certificate in Repository

Place the certificate file here:

```
backend_services/storage/cert/ca.pem
```

**Important**: Make sure the file is committed to Git:

```bash
# Check if file exists
ls backend_services/storage/cert/ca.pem

# If it exists, add to Git (if not already ignored)
git add backend_services/storage/cert/ca.pem
git commit -m "Add Aiven MySQL CA certificate"
git push origin main
```

#### Step 3: Update Render Environment Variable

In **Render Dashboard** → Your Service → **Environment**:

**Remove the old variable:**

```env
MYSQL_ATTR_SSL_CA="C:/Users/junyi/Downloads/kalmnest/kalmnest/backend_services/storage/cert/ca.pem"
```

**Add the correct Linux path:**

```env
MYSQL_ATTR_SSL_CA=/var/www/html/storage/cert/ca.pem
```

**Or use relative path (recommended):**

```env
MYSQL_ATTR_SSL_CA=storage/cert/ca.pem
```

The code will automatically convert this to the full path.

#### Step 4: Optional - Set SSL Verification

```env
DB_SSL_VERIFY=true
```

This enables full SSL verification (most secure).

---

### Option 2: Disable SSL Verification (Quick Fix, Less Secure)

If you don't have the CA certificate or want a quick fix:

#### Step 1: Remove Certificate Path

In **Render Dashboard** → **Environment Variables**:

**Remove or leave empty:**

```env
MYSQL_ATTR_SSL_CA=
```

#### Step 2: Disable SSL Verification

```env
DB_SSL_VERIFY=false
```

**Note**: The code automatically detects Aiven hosts and enables SSL without verification if no certificate is provided.

---

## 🔧 How the Fix Works

The updated `config/database.php` now:

1. **Auto-detects Aiven hosts** by checking for `aivencloud.com` or `aiven.io` in the hostname
2. **Normalizes paths** - Converts Windows paths to Linux paths automatically
3. **Handles missing certificates** - Falls back to SSL without verification if certificate file doesn't exist
4. **Validates file existence** - Checks if certificate file exists before using it

---

## 📋 Environment Variables Checklist

### Required (Already Set)

```env
DB_CONNECTION=mysql
DB_HOST=kalmnest-rickytan5350-1f54.h.aivencloud.com
DB_PORT=19938
DB_DATABASE=codeplay_db
DB_USERNAME=your_username
DB_PASSWORD=your_password
```

### For SSL with Certificate (Option 1)

```env
MYSQL_ATTR_SSL_CA=/var/www/html/storage/cert/ca.pem
# OR
MYSQL_ATTR_SSL_CA=storage/cert/ca.pem
DB_SSL_VERIFY=true
```

### For SSL without Certificate (Option 2)

```env
MYSQL_ATTR_SSL_CA=
DB_SSL_VERIFY=false
```

**Note**: If `MYSQL_ATTR_SSL_CA` is empty or not set, the code automatically enables SSL without verification for Aiven hosts.

---

## 🧪 Testing After Fix

### 1. Test Database Connection

```bash
# In Render Shell or via API
curl https://kalmnest-k2os.onrender.com/api/health
```

Should return `200 OK` (no database errors).

### 2. Test Login Endpoint

```javascript
fetch("https://kalmnest-k2os.onrender.com/api/login", {
    method: "POST",
    credentials: "include",
    headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
    },
    body: JSON.stringify({
        email: "test@example.com",
        password: "password",
        device_name: "web-browser",
    }),
})
    .then((response) => {
        console.log("Status:", response.status);
        console.log(
            "CORS Origin:",
            response.headers.get("Access-Control-Allow-Origin")
        );
        return response.json();
    })
    .then(console.log)
    .catch(console.error);
```

**Expected Results:**

-   ✅ Status: `200` (success) or `422` (validation error) or `401` (auth error)
-   ✅ **NOT** `500` (server error)
-   ✅ CORS Origin: `https://kalmnest-one.vercel.app` (present)
-   ✅ Error messages visible (not blocked by browser)

---

## 🐛 Troubleshooting

### Issue: Still Getting "Cannot connect to MySQL using SSL"

**Check 1: Certificate File Exists**

```bash
# In Render Shell
ls -l /var/www/html/storage/cert/ca.pem
```

If file doesn't exist:

-   Make sure certificate is committed to Git
-   Check Dockerfile copies the file
-   Redeploy service

**Check 2: Environment Variable**

```bash
# In Render Shell
echo $MYSQL_ATTR_SSL_CA
```

Should show `/var/www/html/storage/cert/ca.pem` or `storage/cert/ca.pem`, **NOT** a Windows path.

**Check 3: Clear Config Cache**

```bash
php artisan config:clear
php artisan config:cache
```

**Check 4: Use Option 2 (Disable Verification)**
If certificate path is still problematic, use Option 2 (disable verification) as a temporary fix.

---

### Issue: Certificate File Not Found

**Solution**: Use Option 2 (disable SSL verification) or:

1. Download certificate from Aiven
2. Place in `backend_services/storage/cert/ca.pem`
3. Commit to Git
4. Update environment variable
5. Redeploy

---

## 📝 Summary

1. ✅ **CORS is fixed** - No more CORS errors
2. ❌ **MySQL SSL path is wrong** - Windows path doesn't work on Linux
3. ✅ **Fix applied** - Code now handles path normalization and fallback
4. ⚠️ **Action required** - Update Render environment variable

**Next Steps:**

1. Choose Option 1 (with certificate) or Option 2 (without verification)
2. Update Render environment variables
3. Redeploy service
4. Test login endpoint

---

## 🔗 Related Files

-   `backend_services/config/database.php` - MySQL SSL configuration
-   `backend_services/Dockerfile` - Ensures cert directory exists
-   `backend_services/storage/cert/` - Certificate storage directory

---

**Last Updated**: 2025-01-10
