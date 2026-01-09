# API 测试指南

## 🎯 后端服务地址

**Base URL**: `https://kalmnest-9xvv.onrender.com`

## ✅ 健康检查端点（无需认证）

### 1. 基础健康检查

```bash
GET https://kalmnest-9xvv.onrender.com/api/health
```

**预期响应**:

```json
{
    "status": "ok",
    "time": "2024-01-01T12:00:00.000000Z"
}
```

### 2. 连接测试

```bash
GET https://kalmnest-9xvv.onrender.com/api/test
```

**预期响应**:

```json
{
    "message": "Laravel connected successfully!"
}
```

## 🔐 认证端点（公开）

### 3. 用户注册

```bash
POST https://kalmnest-9xvv.onrender.com/api/user
Content-Type: application/json

{
  "name": "测试用户",
  "email": "test@example.com",
  "password": "password123",
  "role_id": 3
}
```

### 4. 用户登录

```bash
POST https://kalmnest-9xvv.onrender.com/api/login
Content-Type: application/json

{
  "email": "test@example.com",
  "password": "password123"
}
```

**预期响应**:

```json
{
    "token": "1|xxxxxxxxxxxxx",
    "user": {
        "user_id": 1,
        "name": "测试用户",
        "email": "test@example.com"
    }
}
```

## 📝 使用 cURL 测试

### Windows PowerShell

```powershell
# 健康检查
Invoke-WebRequest -Uri "https://kalmnest-9xvv.onrender.com/api/health" -Method GET

# 连接测试
Invoke-WebRequest -Uri "https://kalmnest-9xvv.onrender.com/api/test" -Method GET

# 登录（需要先注册用户）
$body = @{
    email = "test@example.com"
    password = "password123"
} | ConvertTo-Json

Invoke-WebRequest -Uri "https://kalmnest-9xvv.onrender.com/api/login" -Method POST -Body $body -ContentType "application/json"
```

### Linux/Mac (cURL)

```bash
# 健康检查
curl https://kalmnest-9xvv.onrender.com/api/health

# 连接测试
curl https://kalmnest-9xvv.onrender.com/api/test

# 登录
curl -X POST https://kalmnest-9xvv.onrender.com/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

## 🌐 使用浏览器测试

直接在浏览器中访问以下 URL：

1. **健康检查**: https://kalmnest-9xvv.onrender.com/api/health
2. **连接测试**: https://kalmnest-9xvv.onrender.com/api/test

## 🧪 使用 Postman 测试

### 导入集合

1. 打开 Postman
2. 创建新请求
3. 设置请求类型和 URL
4. 对于 POST 请求，在 Body 标签中选择"raw"和"JSON"

### 示例请求

**健康检查**:

-   Method: `GET`
-   URL: `https://kalmnest-9xvv.onrender.com/api/health`

**登录**:

-   Method: `POST`
-   URL: `https://kalmnest-9xvv.onrender.com/api/login`
-   Headers: `Content-Type: application/json`
-   Body (raw JSON):

```json
{
    "email": "test@example.com",
    "password": "password123"
}
```

## 🔒 需要认证的端点

获取 token 后，在请求头中添加：

```
Authorization: Bearer {your_token}
```

### 示例：获取当前用户信息

```bash
GET https://kalmnest-9xvv.onrender.com/api/user
Headers:
  Authorization: Bearer 1|xxxxxxxxxxxxx
```

## 📊 常用 API 端点列表

### 公开端点（无需认证）

-   `GET /api/health` - 健康检查
-   `GET /api/test` - 连接测试
-   `POST /api/login` - 登录
-   `POST /api/user` - 注册
-   `GET /api/notes` - 获取笔记列表
-   `GET /api/achievements` - 获取成就列表

### 需要认证的端点

-   `GET /api/user` - 获取当前用户信息
-   `GET /api/user/role` - 获取用户角色
-   `POST /api/logout` - 登出
-   `GET /api/users` - 获取用户列表
-   `GET /api/classes` - 获取班级列表
-   `GET /api/levels` - 获取关卡列表

## 🐛 调试 500 错误

如果遇到 500 错误，检查以下内容：

1. **查看 Render 日志**:

    - 登录 Render Dashboard
    - 进入服务页面
    - 查看"Logs"标签页

2. **检查环境变量**:

    - 确保所有必需的环境变量都已设置
    - 特别是 `APP_KEY`, `DB_*`, `APP_URL`

3. **检查存储权限**:

    - 确保 `storage` 和 `bootstrap/cache` 目录有写权限

4. **测试 API 端点**:
    - 先测试 `/api/health` 确认服务运行
    - 再测试其他端点定位问题

## 📝 测试检查清单

-   [ ] `/api/health` 返回 `{"status":"ok"}`
-   [ ] `/api/test` 返回成功消息
-   [ ] 可以成功注册新用户
-   [ ] 可以成功登录并获取 token
-   [ ] 使用 token 可以访问受保护的端点
-   [ ] 数据库连接正常
-   [ ] 文件上传功能正常（如果使用）
