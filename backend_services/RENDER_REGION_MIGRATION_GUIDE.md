# 🌏 Render 区域迁移指南 - 删除并重建服务

## ⚠️ 重要提示

由于 Render 不允许直接更改区域，我们需要删除旧服务并创建新服务。本指南将帮助您安全地完成迁移，**确保零数据丢失**。

---

## 📋 迁移前准备清单

### 1. 备份当前配置 ✅

在删除服务之前，**必须**备份以下信息：

#### A. 环境变量列表

1. 在 Render Dashboard 中：
   - 进入您的 Web Service
   - 点击 **Environment** 标签
   - **截图或复制所有环境变量**（包括 Key 和 Value）

2. 或者使用 API 获取（如果有 API Key）：
   ```bash
   curl -H "Authorization: Bearer YOUR_API_KEY" \
     https://api.render.com/v1/services/YOUR_SERVICE_ID/env-vars
   ```

#### B. 服务配置信息

记录以下信息：

- ✅ **服务名称**: `kalmnest` (或您的服务名)
- ✅ **Dockerfile 路径**: `backend_services/Dockerfile` (或您的路径)
- ✅ **Root Directory**: `backend_services` (如果有设置)
- ✅ **Health Check Path**: `/api/health` (或您的路径)
- ✅ **Instance Type**: Free/Starter/Standard (记录当前类型)
- ✅ **Auto-Deploy**: 是否启用
- ✅ **Branch**: `main` (或您的分支)

#### C. 数据库连接信息

确认数据库信息（这些不会改变）：

- ✅ **DB_HOST**: `your-aiven-host.aivencloud.com`
- ✅ **DB_PORT**: `19938` (或您的端口)
- ✅ **DB_DATABASE**: `codeplay_db` (或您的数据库名)
- ✅ **DB_USERNAME**: (您的用户名)
- ✅ **DB_PASSWORD**: (您的密码)

**注意**: 数据库在 Aiven，不受 Render 区域影响，所以数据库连接信息保持不变。

---

## 🚀 迁移步骤

### 步骤 1: 备份环境变量（最重要）📝

1. 打开 Render Dashboard
2. 进入您的 Web Service
3. 点击 **Environment** 标签
4. **复制所有环境变量到文本文件**，格式如下：

```env
APP_NAME=KalmNest
APP_ENV=production
APP_KEY=base64:your-app-key-here
APP_DEBUG=false
APP_URL=https://your-service.onrender.com

DB_CONNECTION=mysql
DB_HOST=your-aiven-host.aivencloud.com
DB_PORT=19938
DB_DATABASE=codeplay_db
DB_USERNAME=your-username
DB_PASSWORD=your-password

# ... 所有其他环境变量 ...
```

**保存这个文件！** 您将在新服务中需要它。

---

### 步骤 2: 记录服务配置 📋

在删除服务之前，记录以下配置：

| 配置项 | 当前值 | 备注 |
|--------|--------|------|
| 服务名称 | `kalmnest` | |
| Dockerfile 路径 | `backend_services/Dockerfile` | |
| Root Directory | `backend_services` | 如果有设置 |
| Health Check Path | `/api/health` | |
| Instance Type | Free/Starter/Standard | |
| Auto-Deploy | 是/否 | |
| Branch | `main` | |

---

### 步骤 3: 删除旧服务 🗑️

1. 在 Render Dashboard 中：
   - 进入您的 Web Service
   - 点击 **Settings** 标签
   - 滚动到底部
   - 点击 **Delete Service** 或 **Delete**
   - 确认删除

**注意**: 
- 删除服务**不会**删除您的代码（代码在 GitHub）
- 删除服务**不会**删除您的数据库（数据库在 Aiven）
- 删除服务**只会**删除 Render 上的服务实例

---

### 步骤 4: 创建新服务（在新区域）🆕

1. 在 Render Dashboard 中：
   - 点击 **New** → **Web Service**
   - 或点击 **New** → **Blueprint**（如果使用配置文件）

2. **连接 GitHub 仓库**:
   - 选择 **Import from GitHub**
   - 选择您的仓库: `RickyTan5350/kalmnest`
   - 点击 **Connect**

3. **配置服务**:

   **基本信息**:
   - **Name**: `kalmnest` (或您喜欢的名称)
   - **Region**: 选择 **Singapore (Southeast Asia)** 或 **Tokyo (Japan)** ⭐
   - **Branch**: `main`
   - **Root Directory**: `backend_services` (如果您的 Dockerfile 在 backend_services 目录)
   - **Runtime**: **Docker**

   **Docker 配置**:
   - **Dockerfile Path**: `Dockerfile` (如果 Root Directory 是 `backend_services`)
   - 或 `backend_services/Dockerfile` (如果 Root Directory 是根目录)

   **其他配置**:
   - **Instance Type**: 选择与之前相同的类型（Free/Starter/Standard）
   - **Health Check Path**: `/api/health`
   - **Auto-Deploy**: 启用（如果需要）

4. **不要点击 Deploy  yet!** 先配置环境变量。

---

### 步骤 5: 配置环境变量 🔐

1. 在创建服务页面，找到 **Environment Variables** 部分
2. **逐个添加**您在步骤 1 中备份的所有环境变量

**重要**: 
- 确保所有环境变量都添加
- 检查每个变量的值是否正确
- 特别注意 `APP_KEY` - 必须使用**相同的值**（否则会话会失效）

**必需的环境变量**（确保这些都在）:

```env
APP_NAME=KalmNest
APP_ENV=production
APP_KEY=base64:your-app-key-here  # ⚠️ 必须与旧服务相同
APP_DEBUG=false
APP_URL=https://your-new-service.onrender.com  # ⚠️ 更新为新服务 URL

# 数据库配置（保持不变）
DB_CONNECTION=mysql
DB_HOST=your-aiven-host.aivencloud.com
DB_PORT=19938
DB_DATABASE=codeplay_db
DB_USERNAME=your-username
DB_PASSWORD=your-password

# 缓存配置（建议添加）
CACHE_STORE=file

# 其他配置...
```

---

### 步骤 6: 部署新服务 🚀

1. 确认所有环境变量已添加
2. 点击 **Create Web Service** 或 **Deploy**
3. 等待构建完成（通常 5-10 分钟）

---

### 步骤 7: 验证部署 ✅

1. **检查服务状态**:
   - 在 Render Dashboard 中查看服务状态
   - 应该显示 **Live** 或 **Running**

2. **测试健康检查**:
   ```bash
   curl https://your-new-service.onrender.com/api/health
   ```
   应该返回 `200 OK`

3. **测试 API 端点**:
   ```bash
   curl https://your-new-service.onrender.com/api/test
   ```

4. **检查日志**:
   - 在 Render Dashboard 中查看 **Logs**
   - 确保没有错误

---

### 步骤 8: 更新前端配置 🔄

如果前端（Vercel）配置了后端 URL，需要更新：

1. 在 Vercel Dashboard 中：
   - 进入您的项目
   - 点击 **Settings** → **Environment Variables**
   - 找到 `CUSTOM_BASE_URL` 或类似变量
   - 更新为新服务的 URL:
     ```
     https://your-new-service.onrender.com
     ```
   - 保存并重新部署前端

---

## ⏱️ 停机时间最小化策略

如果您需要最小化停机时间，可以使用以下策略：

### 策略 1: 并行运行（推荐）

1. **创建新服务**（在新区域）
2. **保持旧服务运行**
3. **测试新服务**确保一切正常
4. **更新前端**指向新服务
5. **删除旧服务**

这样可以在新服务完全正常后再切换。

### 策略 2: 快速切换

1. **提前创建新服务**
2. **测试新服务**
3. **在低峰期**更新前端配置
4. **删除旧服务**

---

## 🔍 验证清单

迁移完成后，检查以下项目：

- [ ] 新服务在目标区域运行
- [ ] 所有环境变量已正确配置
- [ ] 健康检查端点返回 `200 OK`
- [ ] 数据库连接正常（检查日志）
- [ ] API 端点正常工作
- [ ] 前端可以连接到新后端
- [ ] 用户认证正常工作（Sanctum）
- [ ] 缓存正常工作（如果配置了）
- [ ] 日志正常写入

---

## 🐛 常见问题

### Q: 删除服务会丢失数据吗？

**A**: 不会。删除服务只删除 Render 上的服务实例，不会影响：
- ✅ GitHub 代码（代码在 GitHub）
- ✅ Aiven 数据库（数据库在 Aiven）
- ✅ 环境变量（您已备份）

### Q: APP_KEY 必须相同吗？

**A**: 是的！如果 `APP_KEY` 不同：
- ❌ 现有用户的会话会失效
- ❌ 加密的数据无法解密
- ❌ 用户需要重新登录

**解决方案**: 使用相同的 `APP_KEY` 值。

### Q: 如何获取旧服务的 APP_KEY？

**A**: 
1. 在删除服务之前，从环境变量中复制
2. 或者从 `.env` 文件（如果有本地备份）
3. 或者从之前的配置备份中获取

### Q: 新服务的 URL 会不同吗？

**A**: 是的，新服务会有新的 URL。例如：
- 旧: `https://kalmnest-k2os.onrender.com`
- 新: `https://kalmnest-xxxx.onrender.com` (不同的 ID)

**解决方案**: 更新前端配置中的后端 URL。

### Q: 可以保留相同的服务名称吗？

**A**: 可以，但 URL 仍然会不同（因为 Render 使用唯一 ID）。

### Q: 迁移后性能会立即改善吗？

**A**: 是的，如果您的用户主要在亚洲：
- 延迟会从 300-500ms 降至 50-100ms
- 响应速度提升 70-80%

---

## 📝 迁移后优化建议

迁移完成后，建议实施以下优化：

1. **切换缓存到文件缓存**:
   ```env
   CACHE_STORE=file
   ```

2. **检查数据库区域**:
   - 登录 Aiven Console
   - 确认数据库区域
   - 如果数据库在美国，考虑迁移到亚洲

3. **监控性能**:
   - 使用 `/api/health` 端点监控响应时间
   - 检查日志中的错误

---

## 🆘 如果遇到问题

### 问题 1: 新服务无法启动

**检查**:
- [ ] 所有环境变量已正确添加
- [ ] `APP_KEY` 已设置
- [ ] 数据库连接信息正确
- [ ] Dockerfile 路径正确

**解决**: 查看 Render 日志，根据错误信息修复。

### 问题 2: 数据库连接失败

**检查**:
- [ ] 数据库连接信息正确
- [ ] Aiven 防火墙允许新 IP（如果需要）
- [ ] SSL 配置正确（如果使用 Aiven）

**解决**: 检查 `AIVEN_SSL_SETUP.md` 文档。

### 问题 3: 前端无法连接后端

**检查**:
- [ ] 前端环境变量已更新为新后端 URL
- [ ] CORS 配置正确
- [ ] `SANCTUM_STATEFUL_DOMAINS` 包含前端域名

**解决**: 检查 `DOMAIN_CONFIGURATION.md` 文档。

---

## 📚 相关文档

- `PERFORMANCE_OPTIMIZATION_GUIDE.md` - 性能优化指南
- `AIVEN_SSL_SETUP.md` - Aiven SSL 配置
- `DOMAIN_CONFIGURATION.md` - 域名配置

---

## ✅ 快速检查清单

在删除旧服务之前，确保：

- [ ] ✅ 已备份所有环境变量
- [ ] ✅ 已记录服务配置信息
- [ ] ✅ 已确认数据库连接信息
- [ ] ✅ 已准备好新服务的配置
- [ ] ✅ 已了解停机时间影响

---

**最后更新**: 2025-01-10

**重要**: 迁移前请仔细阅读本指南，确保所有步骤都已完成。
