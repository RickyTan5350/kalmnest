# Render.com Docker Deployment Guide for Laravel

Since Render.com doesn't natively support PHP, we need to use Docker to deploy your Laravel application.

## 📋 Configuration Steps

### 1. Language Selection

**Select**: `Docker` (not PHP, as it's not available)

### 2. Region Selection

**Select**: `Singapore (Southeast Asia)`

**Why Singapore?**

- ✅ Closest region to Malaysia
- ✅ Lowest latency for Malaysian users
- ✅ Better performance and faster response times
- ⚠️ **Note**: Region cannot be changed after deployment, so choose carefully

**Impact of Region Choice:**

- **Latency**: Singapore will give you ~10-50ms latency from Malaysia (vs 200-300ms from US regions)
- **Performance**: Faster response times for your users
- **Cost**: Same pricing regardless of region
- **No negative impact**: Choosing Singapore is the best option for Malaysia

### 3. Complete Configuration

| Field                 | Value                                                 |
| --------------------- | ----------------------------------------------------- |
| **Name**              | `kalmnest-api`                                        |
| **Language**          | `Docker` ⚠️ **Select this**                           |
| **Branch**            | `class-module-main`                                   |
| **Region**            | `Singapore (Southeast Asia)` ✅ **Best for Malaysia** |
| **Root Directory**    | `backend_services`                                    |
| **Build Command**     | _(Leave empty - Docker will use Dockerfile)_          |
| **Start Command**     | _(Leave empty - Docker will use Dockerfile CMD)_      |
| **Instance Type**     | `Free`                                                |
| **Health Check Path** | `/up` or `/api/health`                                |

### 4. Environment Variables

Add these environment variables in Render:

```env
APP_NAME=Kalmnest
APP_ENV=production
APP_KEY=base64:YOUR_APP_KEY_HERE
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

LOG_CHANNEL=stderr
LOG_LEVEL=error
```

### 5. Pre-Deploy Command (Optional)

You can add this to run migrations automatically:

```bash
php artisan migrate --force
```

**Note**: For first deployment, it's safer to run migrations manually after deployment succeeds.

---

## 🐳 How Docker Works on Render

1. Render detects the `Dockerfile` in your `backend_services` directory
2. It builds the Docker image using the Dockerfile
3. It runs the container with the CMD specified in Dockerfile
4. Your Laravel app runs inside the Docker container

---

## ✅ Quick Setup Checklist

- [ ] Select **Docker** as Language
- [ ] Select **Singapore** as Region
- [ ] Set **Root Directory** to `backend_services`
- [ ] Leave **Build Command** and **Start Command** empty (Docker handles this)
- [ ] Add all environment variables
- [ ] Set **Health Check Path** to `/up`
- [ ] Click "Create Web Service"

---

## 🔧 After Deployment

1. **Run Database Migrations**:

   - Go to Render Dashboard → Your Service → Shell
   - Run: `php artisan migrate --force`

2. **Test Your API**:
   - Visit: `https://kalmnest-api.onrender.com/api/health`
   - Should return: `{"status":"ok"}`

---

## 📝 Notes

- **Dockerfile** is already created in `backend_services/Dockerfile`
- **Region cannot be changed** after deployment - Singapore is the best choice for Malaysia
- **Free tier** will sleep after 15 minutes of inactivity
- First deployment takes 5-10 minutes

---

## 🚀 Ready to Deploy!

Follow the checklist above and you're good to go!
