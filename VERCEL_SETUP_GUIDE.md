# Vercel 部署配置指南 - Flutter Web Frontend

## 📋 快速配置（Vercel Dashboard）

根据您提供的 Vercel Dashboard 配置界面，请按以下步骤填写：

### ✅ 基本设置

| 设置项 | 值 |
|--------|-----|
| **Vercel Team** | `TAN LI JI's projects` |
| **Plan** | `Hobby` |
| **Project Name** | `kalmnest` |
| **GitHub Repository** | `RickyTan5350/kalmnest` |
| **Branch** | `main` |
| **Framework Preset** | **Other** 或 **Other (No Framework)** |
| **Root Directory** | `./` |

### ⚙️ 构建配置

#### 方法 1: 使用构建脚本（推荐）

**Build Command**:
```bash
bash build-flutter-web.sh
```

**或者使用 npm 脚本**:
```bash
npm run vercel-build
```

**Install Command**:
```bash
npm install
```

**Output Directory**:
```
flutter_codelab/build/web
```

#### 方法 2: 预构建方法（最简单，如果已在本地构建）

如果您已经在本地或通过 GitHub Actions 构建了 Flutter Web：

**Build Command**:
```bash
echo "Using pre-built Flutter Web files"
```

**Install Command**:
```bash
echo "No installation needed"
```

**Output Directory**:
```
flutter_codelab/build/web
```

### 🔐 环境变量配置

在 **"Environment Variables"** 部分添加：

**Key**: `CUSTOM_BASE_URL`  
**Value**: `https://your-render-backend-url.onrender.com`  
**Environment**: 选择 **Production**, **Preview** (和 **Development** 如果需要)

**示例**:
```
CUSTOM_BASE_URL=https://kalmnest-api.onrender.com
```

**⚠️ 重要**:
- ✅ 使用 HTTPS URL
- ✅ 不要包含尾随斜杠 `/`
- ✅ 不要包含 `/api` 后缀（代码会自动添加）
- ✅ 确保 URL 是可访问的

### 📝 完整配置示例

#### 在 Vercel Dashboard 中设置：

**General Settings:**
- Project Name: `kalmnest`
- Framework Preset: **Other**
- Root Directory: `./`

**Build & Development Settings:**
- Build Command: `bash build-flutter-web.sh` 或 `npm run vercel-build`
- Output Directory: `flutter_codelab/build/web`
- Install Command: `npm install`

**Environment Variables:**
```
CUSTOM_BASE_URL = https://your-render-backend-url.onrender.com
```

## 🚀 部署步骤详解

### Step 1: 准备配置文件

确保以下文件已提交到 GitHub:

- ✅ `vercel.json` - Vercel 配置文件
- ✅ `package.json` - 构建脚本
- ✅ `build-flutter-web.sh` - Flutter 构建脚本
- ✅ `.github/workflows/build-flutter-web.yml` - GitHub Actions（可选）

### Step 2: 在 Vercel Dashboard 中创建项目

1. 登录 [Vercel Dashboard](https://vercel.com/dashboard)
2. 点击 **"New Project"** 或 **"Add New..." → "Project"**
3. 选择 **"Import Git Repository"**
4. 在搜索框中输入 `RickyTan5350/kalmnest`
5. 选择仓库 `RickyTan5350/kalmnest`
6. 点击 **"Import"**

### Step 3: 配置项目

#### 3.1 基本信息

- **Project Name**: `kalmnest`
- **Framework Preset**: 选择 **"Other"**
- **Root Directory**: 保持默认 `./`

#### 3.2 构建和输出设置

**Build Command**:
有两种选择：

**选项 A（推荐）**: 使用构建脚本
```
bash build-flutter-web.sh
```

**选项 B**: 使用 npm 脚本
```
npm run vercel-build
```

**Output Directory**:
```
flutter_codelab/build/web
```

**Install Command**:
```
npm install
```

#### 3.3 环境变量

点击 **"Environment Variables"** 或 **"Add Environment Variable"**：

1. 点击 **"Add New"** 或 **"Add Environment Variable"**
2. 填写：
   - **Key**: `CUSTOM_BASE_URL`
   - **Value**: `https://your-render-backend-url.onrender.com`
   - **Environment**: 勾选 **Production** 和 **Preview**
3. 点击 **"Save"** 或 **"Add"**

#### 3.4 部署

点击 **"Deploy"** 按钮开始部署。

### Step 4: 等待构建完成

- 首次构建可能需要 **10-15 分钟**（需要下载 Flutter SDK）
- 后续构建会更快（有缓存）
- 可以在 Vercel Dashboard 的 **"Deployments"** 页面查看构建日志

### Step 5: 验证部署

构建成功后：

1. **获取部署 URL**: 例如 `https://kalmnest.vercel.app`
2. **访问部署 URL**: 打开浏览器访问该 URL
3. **检查功能**:
   - [ ] 页面加载正常
   - [ ] 登录功能正常
   - [ ] API 请求成功
   - [ ] 路由导航正常

## 🔧 高级配置

### 自定义域名

1. 在 Vercel Dashboard → Project → Settings → Domains
2. 添加您的自定义域名
3. 按照提示配置 DNS 记录

### 自动部署

**启用自动部署**:
- Vercel 默认会为每次推送到 `main` 分支自动部署
- 每个 Pull Request 会创建预览部署

**配置分支**:
- Production Branch: `main`
- Preview Deployments: 所有分支和 PR

### 环境变量管理

**不同环境的变量**:
- **Production**: 生产环境（main 分支）
- **Preview**: 预览环境（PR 和其他分支）
- **Development**: 本地开发环境（`vercel dev`）

**示例**:
```
Production:  CUSTOM_BASE_URL=https://kalmnest-api.onrender.com
Preview:     CUSTOM_BASE_URL=https://staging-api.onrender.com
Development: CUSTOM_BASE_URL=http://localhost:8000
```

## ⚠️ 重要注意事项

### 1. Flutter SDK 可用性

Vercel 的默认构建环境**不包含 Flutter SDK**，因此：

- **方案 A（推荐）**: 使用 `build-flutter-web.sh` 脚本自动下载 Flutter SDK
- **方案 B**: 在本地构建后提交 `build/web` 目录到 Git
- **方案 C**: 使用 GitHub Actions 构建后自动部署

### 2. 构建时间限制

- **Hobby Plan**: 构建时间限制为 45 分钟
- **Pro Plan**: 构建时间限制为 6 小时
- 首次构建可能需要 10-15 分钟（下载 Flutter SDK）
- 建议使用构建缓存以加快后续构建

### 3. 文件大小限制

- 单个文件最大 **50 MB**（超过会收到警告）
- 如果 Unity WASM 文件超过限制，考虑：
  - 使用 Git LFS
  - 将文件移到 CDN
  - 使用 Vercel 的文件上传功能

### 4. 环境变量

- **不要提交敏感信息**到 Git
- 使用 Vercel 环境变量存储 API 密钥等
- 环境变量在构建时可用

## 🐛 故障排除

### 问题 1: 构建失败 - Flutter 未找到

**错误**: `flutter: command not found` 或 `bash: flutter: command not found`

**解决方案**:
1. 确保 `build-flutter-web.sh` 脚本已提交到 Git
2. 确保脚本有执行权限（在本地运行：`chmod +x build-flutter-web.sh`）
3. 或者使用预构建方法（在本地构建后提交）

### 问题 2: 构建超时

**错误**: Build timeout 或 Build exceeded maximum duration

**解决方案**:
1. 使用预构建方法（避免在 Vercel 上构建）
2. 优化构建脚本（减少不必要的步骤）
3. 升级到 Pro Plan（更长构建时间）

### 问题 3: 404 错误 - 路由不工作

**错误**: 刷新页面或直接访问路由显示 404

**解决方案**:
1. 确保 `vercel.json` 中的 `rewrites` 配置正确
2. 确保构建时使用了 `--base-href /` 参数
3. 检查 `index.html` 中的 base href 设置

### 问题 4: API 请求失败 - CORS 错误

**错误**: CORS policy blocking requests

**解决方案**:
1. 在后端（Render）配置 CORS 允许 Vercel 域名
2. 在 Laravel 的 `config/cors.php` 中添加：
   ```php
   'allowed_origins' => [
       'https://kalmnest.vercel.app',
       'https://*.vercel.app',
   ],
   ```

### 问题 5: 环境变量未生效

**错误**: API 仍使用默认 URL（kalmnest.test）

**解决方案**:
1. 确认环境变量名称：`CUSTOM_BASE_URL`（区分大小写）
2. 确认变量已添加到正确的环境（Production/Preview）
3. 重新部署以应用新的环境变量
4. 检查构建日志确认变量已加载

## 📋 部署前检查清单

**代码准备：**
- [ ] `vercel.json` 已创建并提交
- [ ] `package.json` 已创建并提交
- [ ] `build-flutter-web.sh` 已创建并提交
- [ ] 代码已推送到 GitHub `main` 分支

**Vercel 配置：**
- [ ] 项目已导入到 Vercel
- [ ] Framework Preset 设置为 **Other**
- [ ] Root Directory 设置为 `./`
- [ ] Build Command 配置正确
- [ ] Output Directory 设置为 `flutter_codelab/build/web`
- [ ] Install Command 配置正确

**环境变量：**
- [ ] `CUSTOM_BASE_URL` 已添加
- [ ] 环境变量值正确（后端 URL）
- [ ] 已选择正确的环境（Production/Preview）

**部署：**
- [ ] 首次部署已启动
- [ ] 构建日志无错误
- [ ] 部署 URL 可访问
- [ ] 主要功能测试通过

## 📚 参考文档

- **Vercel 文档**: [https://vercel.com/docs](https://vercel.com/docs)
- **Flutter Web 部署**: [https://docs.flutter.dev/deployment/web](https://docs.flutter.dev/deployment/web)
- **Vercel CLI**: [https://vercel.com/docs/cli](https://vercel.com/docs/cli)

## 🎉 部署成功后

部署成功后，您将获得：

1. **生产 URL**: `https://kalmnest.vercel.app`（或自定义域名）
2. **自动部署**: 每次推送到 `main` 分支自动部署
3. **预览部署**: 每个 PR 自动创建预览 URL
4. **部署日志**: 在 Vercel Dashboard 查看详细日志

---

**部署日期**: _______________
**部署 URL**: https://_______________
**后端 API URL**: https://_______________
**状态**: ☐ 成功 ☐ 需要修复
