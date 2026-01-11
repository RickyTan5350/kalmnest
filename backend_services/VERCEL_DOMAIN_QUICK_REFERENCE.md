# 🚀 Vercel 域名配置快速参考

## 📍 你的域名

### Vercel 前端
- `kalmnest-git-main-tan-li-jis-projects.vercel.app`
- `kalmnest-mclv2vdnk-tan-li-jis-projects.vercel.app`
- `kalmnest-one.vercel.app` (自定义域名)

### Render 后端
- `https://kalmnest-k2os.onrender.com`

## ⚡ 快速配置（复制粘贴）

### Render 后端环境变量

在 **Render Dashboard** → 你的服务 → **Environment** 中添加：

```bash
SANCTUM_STATEFUL_DOMAINS=kalmnest-git-main-tan-li-jis-projects.vercel.app,kalmnest-mclv2vdnk-tan-li-jis-projects.vercel.app,kalmnest-one.vercel.app,localhost,localhost:3000

SESSION_DOMAIN=

SESSION_SECURE_COOKIE=true

SESSION_SAME_SITE=none

FRONTEND_URL=https://kalmnest-one.vercel.app
```

### Vercel 前端环境变量

在 **Vercel Dashboard** → 你的项目 → **Settings** → **Environment Variables** 中添加：

```bash
# 根据你的框架选择其中一个：
VITE_API_URL=https://kalmnest-k2os.onrender.com
# 或
NEXT_PUBLIC_API_URL=https://kalmnest-k2os.onrender.com
# 或
REACT_APP_API_URL=https://kalmnest-k2os.onrender.com
```

## ✅ 配置检查清单

- [ ] `SANCTUM_STATEFUL_DOMAINS` 包含所有 Vercel 域名
- [ ] `SANCTUM_STATEFUL_DOMAINS` 不包含 `https://` 前缀
- [ ] `SESSION_DOMAIN` 留空或未设置
- [ ] `SESSION_SECURE_COOKIE=true`
- [ ] `SESSION_SAME_SITE=none`
- [ ] 前端环境变量指向正确的后端 URL
- [ ] 重新部署后端服务
- [ ] 清除浏览器缓存和 Cookies
- [ ] 测试登录功能

## 🔍 测试命令

在浏览器控制台（前端域名）运行：

```javascript
// 测试健康检查
fetch('https://kalmnest-k2os.onrender.com/api/health', {
  credentials: 'include'
}).then(r => r.json()).then(console.log);

// 测试登录
fetch('https://kalmnest-k2os.onrender.com/api/login', {
  method: 'POST',
  credentials: 'include',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    email: 'your-email@example.com',
    password: 'your-password'
  })
}).then(r => r.json()).then(console.log);
```

## 📚 详细文档

完整配置说明请参考：`DOMAIN_CONFIGURATION.md`
