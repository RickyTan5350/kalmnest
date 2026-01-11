# Browser Testing Commands for CORS Debugging

## Open Browser Console

1. Go to: `https://kalmnest-one.vercel.app`
2. Press `F12` to open Developer Tools
3. Go to **Console** tab
4. Copy and paste these commands one by one

## Test 1: Check CORS Configuration (OPTIONS Preflight)

```javascript
fetch('https://kalmnest-k2os.onrender.com/api/login', {
  method: 'OPTIONS',
  headers: {
    'Origin': 'https://kalmnest-one.vercel.app',
    'Access-Control-Request-Method': 'POST',
    'Access-Control-Request-Headers': 'content-type, authorization',
  }
})
.then(response => {
  console.log('=== OPTIONS Response ===');
  console.log('Status:', response.status);
  console.log('Status Text:', response.statusText);
  console.log('\n=== CORS Headers ===');
  const corsHeaders = {
    'Access-Control-Allow-Origin': response.headers.get('Access-Control-Allow-Origin'),
    'Access-Control-Allow-Methods': response.headers.get('Access-Control-Allow-Methods'),
    'Access-Control-Allow-Headers': response.headers.get('Access-Control-Allow-Headers'),
    'Access-Control-Allow-Credentials': response.headers.get('Access-Control-Allow-Credentials'),
    'Access-Control-Max-Age': response.headers.get('Access-Control-Max-Age'),
  };
  console.table(corsHeaders);
  console.log('\n=== All Headers ===');
  response.headers.forEach((value, key) => {
    console.log(`${key}: ${value}`);
  });
  return response;
})
.catch(error => {
  console.error('ERROR:', error);
});
```

**Expected**: Should see CORS headers with `Access-Control-Allow-Origin: https://kalmnest-one.vercel.app`

## Test 2: Test Health Endpoint (Simple GET)

```javascript
fetch('https://kalmnest-k2os.onrender.com/api/health', {
  method: 'GET',
  credentials: 'include',
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  }
})
.then(response => {
  console.log('=== Health Check Response ===');
  console.log('Status:', response.status);
  console.log('CORS Origin:', response.headers.get('Access-Control-Allow-Origin'));
  console.log('CORS Credentials:', response.headers.get('Access-Control-Allow-Credentials'));
  return response.json();
})
.then(data => {
  console.log('Response Data:', data);
})
.catch(error => {
  console.error('ERROR:', error);
});
```

**Expected**: Should return `{status: "ok", time: "..."}` with CORS headers

## Test 3: Test Login Endpoint (POST with device_name)

```javascript
fetch('https://kalmnest-k2os.onrender.com/api/login', {
  method: 'POST',
  credentials: 'include',
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Origin': 'https://kalmnest-one.vercel.app',
  },
  body: JSON.stringify({
    email: 'your-email@example.com',
    password: 'your-password',
    device_name: 'web-browser'  // Required field!
  })
})
.then(response => {
  console.log('=== Login Response ===');
  console.log('Status:', response.status);
  console.log('Status Text:', response.statusText);
  console.log('\n=== CORS Headers ===');
  console.log('Access-Control-Allow-Origin:', response.headers.get('Access-Control-Allow-Origin'));
  console.log('Access-Control-Allow-Credentials:', response.headers.get('Access-Control-Allow-Credentials'));
  console.log('\n=== All Response Headers ===');
  response.headers.forEach((value, key) => {
    console.log(`${key}: ${value}`);
  });
  return response.json();
})
.then(data => {
  console.log('\n=== Response Data ===');
  console.log(data);
})
.catch(error => {
  console.error('ERROR:', error);
  console.error('Error Details:', error.message);
});
```

**Expected**: Should return login response or validation error, with CORS headers present

## Test 4: Check Network Tab

1. Go to **Network** tab in Developer Tools
2. Clear network log (trash icon)
3. Run Test 3 (login) again
4. Click on the `login` request
5. Check **Headers** tab:
   - **Request Headers**: Look for `Origin: https://kalmnest-one.vercel.app`
   - **Response Headers**: Look for `Access-Control-Allow-Origin`

## Test 5: Test with cURL (Copy to Terminal)

```bash
# Test OPTIONS preflight
curl -X OPTIONS \
  -H "Origin: https://kalmnest-one.vercel.app" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: content-type, authorization" \
  -v https://kalmnest-k2os.onrender.com/api/login 2>&1 | grep -i "access-control"

# Test actual POST request
curl -X POST \
  -H "Origin: https://kalmnest-one.vercel.app" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"email":"test@example.com","password":"test","device_name":"curl-test"}' \
  -v https://kalmnest-k2os.onrender.com/api/login 2>&1 | grep -i "access-control"
```

## Test 6: Check Response Headers (Detailed)

```javascript
// This will show ALL headers in a readable format
fetch('https://kalmnest-k2os.onrender.com/api/health', {
  method: 'GET',
  credentials: 'include',
})
.then(async response => {
  const headers = {};
  response.headers.forEach((value, key) => {
    headers[key] = value;
  });
  console.log('=== All Response Headers ===');
  console.table(headers);
  console.log('\n=== CORS Specific ===');
  console.log('Access-Control-Allow-Origin:', headers['access-control-allow-origin']);
  console.log('Access-Control-Allow-Credentials:', headers['access-control-allow-credentials']);
  console.log('Access-Control-Allow-Methods:', headers['access-control-allow-methods']);
  console.log('Access-Control-Allow-Headers:', headers['access-control-allow-headers']);
  return response.json();
})
.then(data => console.log('Data:', data))
.catch(console.error);
```

## What to Look For

### ✅ Success Indicators:
- `Access-Control-Allow-Origin: https://kalmnest-one.vercel.app` (exact match)
- `Access-Control-Allow-Credentials: true`
- `Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS`
- Status 200 for OPTIONS requests
- No CORS errors in console

### ❌ Problem Indicators:
- `Access-Control-Allow-Origin: null`
- No `Access-Control-Allow-Origin` header at all
- CORS error in browser console
- Status 404 or 500 for OPTIONS requests

## If CORS Headers Are Still Null

1. **Check Render Logs**: 
   - Go to Render Dashboard → Your Service → Logs
   - Look for errors or warnings

2. **Verify Config File**:
   - Ensure `config/cors.php` exists
   - Check that it's been deployed

3. **Clear Config Cache** (if you have SSH access):
   ```bash
   php artisan config:clear
   php artisan cache:clear
   ```

4. **Check Middleware Order**:
   - CORS middleware should be first in the stack
   - Verify in `bootstrap/app.php`

## Report Back

After running these tests, provide:
1. Output from Test 1 (OPTIONS request)
2. Output from Test 3 (Login request)
3. Screenshot of Network tab showing request/response headers
4. Any errors from Render logs
