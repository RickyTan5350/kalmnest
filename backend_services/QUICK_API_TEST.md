# 🚀 快速API测试指南

## 后端地址
**Base URL**: `https://kalmnest-k2os.onrender.com`

## ✅ 立即测试（无需工具）

### 在浏览器中直接访问：

1. **健康检查**（最简单）:
   ```
   https://kalmnest-k2os.onrender.com/api/health
   ```
   应该返回：`{"status":"ok","time":"..."}`

2. **连接测试**:
   ```
   https://kalmnest-k2os.onrender.com/api/test
   ```
   应该返回：`{"message":"Laravel connected successfully!"}`

3. **根路径**（修复后）:
   ```
   https://kalmnest-k2os.onrender.com/
   ```
   应该返回API信息

## 🧪 使用浏览器开发者工具测试

1. 打开浏览器（Chrome/Firefox）
2. 按 `F12` 打开开发者工具
3. 切换到 "Network"（网络）标签
4. 在地址栏输入：`https://kalmnest-k2os.onrender.com/api/health`
5. 查看响应内容

## 📱 使用 PowerShell 测试（Windows）

```powershell
# 测试健康检查
Invoke-RestMethod -Uri "https://kalmnest-k2os.onrender.com/api/health" -Method GET

# 测试连接
Invoke-RestMethod -Uri "https://kalmnest-k2os.onrender.com/api/test" -Method GET

# 测试登录（需要先有用户）
$loginData = @{
    email = "your-email@example.com"
    password = "your-password"
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://kalmnest-k2os.onrender.com/api/login" -Method POST -Body $loginData -ContentType "application/json"
```

## 🔍 诊断500错误

如果根路径 `/` 返回500错误，但 `/api/health` 正常，说明：

✅ **API正常工作** - 问题只在Web路由

可能的原因：
1. 视图文件问题
2. 数据库连接问题（如果视图需要数据库）
3. 环境变量缺失

### 检查步骤：

1. **测试API端点**（确认后端正常）:
   - ✅ `/api/health` - 应该返回OK
   - ✅ `/api/test` - 应该返回成功消息

2. **查看Render日志**:
   - 登录 Render Dashboard
   - 进入你的服务
   - 点击 "Logs" 标签
   - 查看错误详情

3. **检查环境变量**（在Render Dashboard中）:
   - `APP_KEY` - 必须设置
   - `APP_URL` - 应该是 `https://kalmnest-k2os.onrender.com`
   - `DB_*` - 数据库配置
   - `APP_DEBUG` - 生产环境应该是 `false`

## 🎯 推荐的测试顺序

1. ✅ 先测试 `/api/health` - 确认服务运行
2. ✅ 再测试 `/api/test` - 确认Laravel正常
3. ✅ 测试 `/api/login` - 确认数据库连接
4. ✅ 最后测试其他端点

## 📝 常用测试命令

### cURL（如果已安装）
```bash
# 健康检查
curl https://kalmnest-k2os.onrender.com/api/health

# 测试连接
curl https://kalmnest-k2os.onrender.com/api/test
```

### JavaScript (在浏览器控制台)
```javascript
// 健康检查
fetch('https://kalmnest-k2os.onrender.com/api/health')
  .then(r => r.json())
  .then(console.log);

// 测试连接
fetch('https://kalmnest-k2os.onrender.com/api/test')
  .then(r => r.json())
  .then(console.log);
```
