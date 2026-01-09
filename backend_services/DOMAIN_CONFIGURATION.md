# 🌐 域名配置指南 - Vercel 前端 + Render 后端

## 📋 概述

本文档说明如何配置前端（Vercel）和后端（Render）的域名环境变量，以确保跨域认证正常工作。

## 🎯 你的域名信息

### Vercel 前端域名

根据你的部署信息：

-   **主要域名**: `kalmnest-git-main-tan-li-jis-projects.vercel.app`
-   **备用域名**: `kalmnest-mclv2vdnk-tan-li-jis-projects.vercel.app`
-   **自定义域名**: `kalmnest-one.vercel.app`

### Render 后端域名

-   **后端地址**: `https://kalmnest-9xvv.onrender.com`

## ⚙️ Render 后端环境变量配置

在 **Render Dashboard** → 你的后端服务 → **Environment** 部分，添加以下环境变量：

### 必需的环境变量

```bash
# Sanctum 状态化域名（最重要！）
SANCTUM_STATEFUL_DOMAINS=kalmnest-git-main-tan-li-jis-projects.vercel.app,kalmnest-mclv2vdnk-tan-li-jis-projects.vercel.app,kalmnest-one.vercel.app,localhost,localhost:3000,127.0.0.1,127.0.0.1:8000

# Session 域名（跨域场景通常留空或设置为 null）
SESSION_DOMAIN=

# Session Cookie 安全设置（HTTPS 必需）
SESSION_SECURE_COOKIE=true

# Session Same-Site 设置（跨域必需）
SESSION_SAME_SITE=none

# 前端 URL（可选，用于 CORS 配置）
FRONTEND_URL=https://kalmnest-one.vercel.app

# 应用 URL（后端地址）
APP_URL=https://kalmnest-9xvv.onrender.com
```

### 详细说明

#### 1. `SANCTUM_STATEFUL_DOMAINS` ⭐ **最重要**

这是 Sanctum 用于识别哪些域名可以接收状态化认证 cookie 的配置。

**格式**: 用逗号分隔的域名列表，**不要包含协议（http://或 https://）**

**你的配置应该是**:

```
SANCTUM_STATEFUL_DOMAINS=kalmnest-git-main-tan-li-jis-projects.vercel.app,kalmnest-mclv2vdnk-tan-li-jis-projects.vercel.app,kalmnest-one.vercel.app,localhost,localhost:3000
```

**注意**:

-   包含所有 Vercel 域名（包括自动生成的和自定义的）
-   包含本地开发域名（localhost）
-   不要包含端口号（除非是 localhost）
-   不要包含 `https://` 前缀

#### 2. `SESSION_DOMAIN`

对于跨域场景（前端和后端在不同域名），通常**留空**或设置为空字符串。

```
SESSION_DOMAIN=
```

或者不设置这个变量（使用默认值 null）。

#### 3. `SESSION_SECURE_COOKIE`

在生产环境（HTTPS）中必须设置为 `true`。

```
SESSION_SECURE_COOKIE=true
```

#### 4. `SESSION_SAME_SITE`

对于跨域认证，必须设置为 `none`。

```
SESSION_SAME_SITE=none
```

**注意**: 当 `SESSION_SAME_SITE=none` 时，`SESSION_SECURE_COOKIE` 必须为 `true`。

#### 5. `FRONTEND_URL`（可选）

用于 CORS 配置或前端重定向，通常设置为你的主要前端域名。

```
FRONTEND_URL=https://kalmnest-one.vercel.app
```

## 🔧 Vercel 前端环境变量配置

在 **Vercel Dashboard** → 你的项目 → **Settings** → **Environment Variables**，添加：

```bash
# 后端 API 地址
VITE_API_URL=https://kalmnest-9xvv.onrender.com
# 或
NEXT_PUBLIC_API_URL=https://kalmnest-9xvv.onrender.com
# 或
REACT_APP_API_URL=https://kalmnest-9xvv.onrender.com
```

**注意**: 根据你使用的前端框架选择正确的变量名：

-   **Vite**: `VITE_API_URL`
-   **Next.js**: `NEXT_PUBLIC_API_URL`
-   **Create React App**: `REACT_APP_API_URL`

## 📝 完整的环境变量清单

### Render 后端（必需）

```bash
# 应用配置
APP_NAME=kalmnest
APP_ENV=production
APP_KEY=你的应用密钥
APP_DEBUG=false
APP_URL=https://kalmnest-9xvv.onrender.com

# Sanctum 配置
SANCTUM_STATEFUL_DOMAINS=kalmnest-git-main-tan-li-jis-projects.vercel.app,kalmnest-mclv2vdnk-tan-li-jis-projects.vercel.app,kalmnest-one.vercel.app,localhost,localhost:3000

# Session 配置
SESSION_DOMAIN=
SESSION_SECURE_COOKIE=true
SESSION_SAME_SITE=none
SESSION_DRIVER=database

# 前端 URL（可选）
FRONTEND_URL=https://kalmnest-one.vercel.app

# 数据库配置
DB_CONNECTION=mysql
DB_HOST=你的数据库主机
DB_PORT=3306
DB_DATABASE=你的数据库名
DB_USERNAME=你的数据库用户名
DB_PASSWORD=你的数据库密码

# 日志配置
LOG_CHANNEL=stderr
LOG_LEVEL=error
```

## 🧪 测试配置

### 1. 测试 CORS

在浏览器控制台（前端域名）运行：

```javascript
fetch("https://kalmnest-9xvv.onrender.com/api/health", {
    method: "GET",
    credentials: "include", // 重要：包含 cookies
    headers: {
        "Content-Type": "application/json",
    },
})
    .then((r) => r.json())
    .then(console.log)
    .catch(console.error);
```

### 2. 测试登录

```javascript
fetch("https://kalmnest-9xvv.onrender.com/api/login", {
    method: "POST",
    credentials: "include", // 重要：包含 cookies
    headers: {
        "Content-Type": "application/json",
    },
    body: JSON.stringify({
        email: "your-email@example.com",
        password: "your-password",
    }),
})
    .then((r) => r.json())
    .then(console.log)
    .catch(console.error);
```

### 3. 检查 Cookie

登录成功后，在浏览器开发者工具的 **Application** → **Cookies** 中，应该能看到：

-   `laravel_session` cookie
-   Cookie 的 `SameSite` 属性应该是 `None`
-   Cookie 的 `Secure` 标志应该是 `true`

## ⚠️ 常见问题

### 问题 1: CORS 错误

**症状**: 浏览器控制台显示 CORS 错误

**解决方案**:

1. 检查 `SANCTUM_STATEFUL_DOMAINS` 是否包含所有前端域名
2. 确保域名格式正确（没有协议，没有尾部斜杠）
3. 确保 `SESSION_SAME_SITE=none` 和 `SESSION_SECURE_COOKIE=true`

### 问题 2: Cookie 未设置

**症状**: 登录成功但 Cookie 未保存

**解决方案**:

1. 检查 `SANCTUM_STATEFUL_DOMAINS` 配置
2. 确保前端请求包含 `credentials: 'include'`
3. 检查浏览器控制台的 Cookie 警告

### 问题 3: 认证失败

**症状**: 登录后无法访问受保护的路由

**解决方案**:

1. 检查请求头是否包含 `Authorization: Bearer {token}`
2. 检查 token 是否正确返回
3. 验证 `SANCTUM_STATEFUL_DOMAINS` 配置

## 🔄 更新配置后的步骤

1. **在 Render 中更新环境变量**
2. **重新部署后端服务**（Render 会自动重启）
3. **清除浏览器缓存和 Cookies**
4. **测试登录功能**

## 📚 参考文档

-   [Laravel Sanctum 文档](https://laravel.com/docs/sanctum)
-   [Sanctum SPA 认证](https://laravel.com/docs/sanctum#spa-authentication)
-   [CORS 配置](https://laravel.com/docs/cors)
