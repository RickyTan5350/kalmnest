# CORS Debugging Guide

## Problem Analysis

### Current Error
```
Access to fetch at 'https://kalmnest-9xvv.onrender.com/api/login' 
from origin 'https://kalmnest-one.vercel.app' 
has been blocked by CORS policy: 
No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

### Root Causes

1. **Missing CORS Configuration File**
   - Laravel 11 requires `config/cors.php` to configure CORS
   - Without this file, CORS middleware doesn't know which origins to allow
   - **Status**: ✅ Fixed - Created `config/cors.php`

2. **CORS Headers Not Being Sent**
   - Backend must send `Access-Control-Allow-Origin` header
   - Backend must send `Access-Control-Allow-Credentials: true` for cookies
   - Backend must handle OPTIONS preflight requests

3. **Environment Variables**
   - `SANCTUM_STATEFUL_DOMAINS` must include all frontend domains
   - `FRONTEND_URL` should be set for CORS configuration

## Solution Implemented

### 1. Created `config/cors.php`

This file configures:
- **Allowed Origins**: All Vercel frontend domains
- **Allowed Methods**: All HTTP methods (`*`)
- **Allowed Headers**: All headers (`*`)
- **Supports Credentials**: `true` (required for cookies)
- **Paths**: `api/*` and `sanctum/csrf-cookie`

### 2. Configuration Details

```php
'paths' => ['api/*', 'sanctum/csrf-cookie'],
'allowed_methods' => ['*'],
'allowed_origins' => [
    'https://kalmnest-one.vercel.app',
    'https://kalmnest-git-main-tan-li-jis-projects.vercel.app',
    'https://kalmnest-mclv2vdnk-tan-li-jis-projects.vercel.app',
    // ... local development domains
],
'allowed_origins_patterns' => [
    '#^https://kalmnest-.*\.vercel\.app$#', // All Vercel preview deployments
],
'supports_credentials' => true,
```

## Testing Steps

### Step 1: Test CORS Headers (Browser Console)

Open your frontend at `https://kalmnest-one.vercel.app` and run:

```javascript
// Test OPTIONS preflight request
fetch('https://kalmnest-9xvv.onrender.com/api/login', {
  method: 'OPTIONS',
  headers: {
    'Origin': 'https://kalmnest-one.vercel.app',
    'Access-Control-Request-Method': 'POST',
    'Access-Control-Request-Headers': 'content-type',
  }
})
.then(response => {
  console.log('CORS Headers:', {
    'Access-Control-Allow-Origin': response.headers.get('Access-Control-Allow-Origin'),
    'Access-Control-Allow-Credentials': response.headers.get('Access-Control-Allow-Credentials'),
    'Access-Control-Allow-Methods': response.headers.get('Access-Control-Allow-Methods'),
    'Access-Control-Allow-Headers': response.headers.get('Access-Control-Allow-Headers'),
  });
  return response;
})
.then(console.log)
.catch(console.error);
```

**Expected Result**: Should see CORS headers in the response.

### Step 2: Test Health Endpoint

```javascript
fetch('https://kalmnest-9xvv.onrender.com/api/health', {
  method: 'GET',
  credentials: 'include',
  headers: {
    'Content-Type': 'application/json',
  }
})
.then(r => r.json())
.then(console.log)
.catch(console.error);
```

**Expected Result**: Should return `{"status":"ok","time":"..."}` without CORS error.

### Step 3: Test Login Endpoint

```javascript
fetch('https://kalmnest-9xvv.onrender.com/api/login', {
  method: 'POST',
  credentials: 'include',
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
  body: JSON.stringify({
    email: 'your-email@example.com',
    password: 'your-password'
  })
})
.then(r => {
  console.log('Status:', r.status);
  console.log('Headers:', {
    'Access-Control-Allow-Origin': r.headers.get('Access-Control-Allow-Origin'),
    'Access-Control-Allow-Credentials': r.headers.get('Access-Control-Allow-Credentials'),
  });
  return r.json();
})
.then(console.log)
.catch(console.error);
```

**Expected Result**: Should return login response without CORS error.

### Step 4: Test with cURL (Server-Side)

```bash
# Test OPTIONS preflight
curl -X OPTIONS \
  -H "Origin: https://kalmnest-one.vercel.app" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: content-type" \
  -v https://kalmnest-9xvv.onrender.com/api/login

# Test actual request
curl -X POST \
  -H "Origin: https://kalmnest-one.vercel.app" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"email":"test@example.com","password":"test"}' \
  -v https://kalmnest-9xvv.onrender.com/api/login
```

**Expected Result**: Should see CORS headers in response.

## Environment Variables Checklist

### Render Backend (Required)

Verify these are set in **Render Dashboard** → **Environment**:

```bash
# CORS & Sanctum
SANCTUM_STATEFUL_DOMAINS=kalmnest-git-main-tan-li-jis-projects.vercel.app,kalmnest-mclv2vdnk-tan-li-jis-projects.vercel.app,kalmnest-one.vercel.app,localhost,localhost:3000

# Session (for cookies)
SESSION_DOMAIN=
SESSION_SECURE_COOKIE=true
SESSION_SAME_SITE=none

# Frontend URL (optional but recommended)
FRONTEND_URL=https://kalmnest-one.vercel.app

# App URL
APP_URL=https://kalmnest-9xvv.onrender.com
```

### Vercel Frontend (Optional)

In **Vercel Dashboard** → **Settings** → **Environment Variables**:

```bash
CUSTOM_BASE_URL=https://kalmnest-9xvv.onrender.com
```

## Debugging Checklist

- [ ] `config/cors.php` file exists and is configured correctly
- [ ] `SANCTUM_STATEFUL_DOMAINS` includes all frontend domains
- [ ] `SESSION_SAME_SITE=none` and `SESSION_SECURE_COOKIE=true`
- [ ] Backend is deployed with latest changes
- [ ] Frontend is deployed with latest changes
- [ ] Test OPTIONS preflight request returns CORS headers
- [ ] Test actual API request works without CORS error
- [ ] Check browser Network tab for CORS headers in response

## Common Issues

### Issue 1: CORS Headers Not Present

**Symptoms**: No `Access-Control-Allow-Origin` header in response

**Solutions**:
1. Verify `config/cors.php` exists and is correct
2. Clear Laravel config cache: `php artisan config:clear`
3. Restart backend service on Render
4. Check that `HandleCors` middleware is enabled in `bootstrap/app.php`

### Issue 2: Credentials Not Working

**Symptoms**: Cookies not being sent/received

**Solutions**:
1. Ensure `supports_credentials: true` in `config/cors.php`
2. Ensure `SESSION_SAME_SITE=none` and `SESSION_SECURE_COOKIE=true`
3. Ensure frontend uses `credentials: 'include'` in fetch requests
4. Ensure `SANCTUM_STATEFUL_DOMAINS` includes frontend domain

### Issue 3: Preflight Request Failing

**Symptoms**: OPTIONS request returns 404 or error

**Solutions**:
1. Ensure `paths` in `config/cors.php` includes `api/*`
2. Check that routes are properly defined
3. Verify middleware is applied to API routes

## Next Steps

1. **Commit and Deploy**:
   ```bash
   git add backend_services/config/cors.php
   git commit -m "Add CORS configuration for Vercel frontend"
   git push origin main
   ```

2. **Wait for Render Deployment**: Render will automatically redeploy

3. **Test Again**: Use the testing steps above

4. **Check Logs**: If still failing, check Render logs for errors

## Additional Resources

- [Laravel CORS Documentation](https://laravel.com/docs/cors)
- [MDN CORS Guide](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)
- [Sanctum SPA Authentication](https://laravel.com/docs/sanctum#spa-authentication)
