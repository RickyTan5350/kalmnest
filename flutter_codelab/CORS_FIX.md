# CORS 错误修复说明

## 问题描述

在 Vercel 部署的前端应用无法访问 Render 后端，出现以下错误：
- `Access to fetch at 'https://kalmnest.test/api/login' from origin 'https://kalmnest-one.vercel.app' has been blocked by CORS policy`
- `Permission was denied for this request to access the 'unknown' address space`

## 问题原因

1. **错误的 API URL**: 前端代码在 Web 环境下默认使用 `https://kalmnest.test/api`（本地开发地址）
2. **浏览器安全限制**: 浏览器阻止对 `.test` 域名的请求（私有地址空间）
3. **环境变量未设置**: `CUSTOM_BASE_URL` 环境变量在 Vercel 中可能未设置

## 解决方案

### 已修复的代码

`lib/constants/api_constants.dart` 已更新：
- 在 Web 环境下，如果没有设置 `CUSTOM_BASE_URL`，默认使用 Render 后端地址
- 生产后端 URL: `https://kalmnest-k2os.onrender.com`

### 环境变量配置（可选但推荐）

在 **Vercel Dashboard** → 你的项目 → **Settings** → **Environment Variables** 中设置：

**Key**: `CUSTOM_BASE_URL`  
**Value**: `https://kalmnest-k2os.onrender.com`  
**Environment**: ✅ Production, ✅ Preview

**注意**:
- ✅ 使用 HTTPS URL
- ✅ 不要包含尾随斜杠 `/`
- ✅ 不要包含 `/api` 后缀（代码会自动添加）

### 为什么现在不需要设置环境变量？

代码已更新为：在 Web 环境下，如果没有设置 `CUSTOM_BASE_URL`，会自动使用 Render 后端地址。这意味着：
- ✅ 即使不设置环境变量，生产环境也能正常工作
- ✅ 设置环境变量可以让你灵活切换后端地址
- ✅ 本地开发时，可以通过设置 `CUSTOM_BASE_URL` 使用本地地址

## 验证修复

1. **重新部署前端**（Vercel 会自动检测代码更改）
2. **测试登录功能**：
   - 打开前端应用
   - 尝试登录
   - 应该能成功连接到后端

3. **检查网络请求**：
   - 打开浏览器开发者工具（F12）
   - 查看 Network 标签
   - API 请求应该指向 `https://kalmnest-k2os.onrender.com/api/...`

## 本地开发配置

如果你在本地开发，可以通过以下方式使用本地后端：

### 方法 1: 设置环境变量（推荐）

在运行 Flutter Web 时设置：
```bash
flutter run -d chrome --dart-define=CUSTOM_BASE_URL=https://kalmnest.test
```

### 方法 2: 修改代码（临时）

在 `api_constants.dart` 中临时修改 `productionBackendUrl` 为本地地址。

## 相关文件

- `lib/constants/api_constants.dart` - API 配置
- `backend_services/DOMAIN_CONFIGURATION.md` - 后端域名配置指南
