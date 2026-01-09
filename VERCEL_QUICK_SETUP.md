# Vercel 快速部署配置指南

## 📋 Vercel Dashboard 配置

根据您提供的 Vercel Dashboard 配置界面，请按以下步骤填写：

### 1. 基本信息

- **Vercel Team**: `TAN LI JI's projects` ✅
- **Plan**: `Hobby` ✅
- **Project Name**: `kalmnest` ✅

### 2. 框架和目录设置

- **Framework Preset**: **Other** 或 **Other (No Framework)**
- **Root Directory**: `./` （项目根目录）

### 3. 构建配置

**⚠️ 重要**: Vercel 默认不包含 Flutter SDK，需要使用以下方法之一：

#### 方法 A: 使用预构建文件（推荐）

如果您已经在本地构建了 Flutter Web，可以：

1. **构建 Flutter Web**（在本地）:
   ```bash
   cd flutter_codelab
   flutter pub get
   flutter build web --release --base-href /
   ```

2. **提交构建文件到 Git**:
   ```bash
   git add flutter_codelab/build/web
   git commit -m "Add Flutter Web build files"
   git push
   ```

3. **在 Vercel 中配置**:
   - **Build Command**: `echo "Using pre-built files"`
   - **Output Directory**: `flutter_codelab/build/web`
   - **Install Command**: `echo "No installation needed"`

#### 方法 B: 使用构建脚本（需要配置）

**Build Command**:
```bash
curl https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.3-stable.tar.xz | tar xJ && export PATH="$PATH:$PWD/flutter/bin" && cd flutter_codelab && flutter pub get && flutter build web --release --base-href /
```

**或者使用我们创建的 package.json 脚本**:
```
npm run vercel-build
```

**Install Command**:
```bash
npm install
```

**或者**:
```bash
cd flutter_codelab && flutter pub get
```

**Output Directory**:
```
flutter_codelab/build/web
```

### 4. 环境变量配置

在 **"Environment Variables"** 部分添加：

| Key | Value | Environment |
|-----|-------|-------------|
| `CUSTOM_BASE_URL` | `https://your-render-backend-url.onrender.com` | Production, Preview |

**示例**:
```
CUSTOM_BASE_URL=https://kalmnest-api.onrender.com
```

**重要**:
- 不要包含尾随斜杠
- 不要包含 `/api` 后缀（代码会自动添加）
- 确保 URL 是可访问的 HTTPS URL

### 5. 完整配置示例

**Project Settings:**
```
Framework Preset: Other
Root Directory: ./
Build Command: npm run vercel-build
Output Directory: flutter_codelab/build/web
Install Command: npm install
```

## 🔧 推荐的配置（使用 package.json）

### 在 Vercel Dashboard 中设置：

1. **Framework Preset**: `Other`

2. **Root Directory**: `./`

3. **Build Command**: 
   ```
   npm run vercel-build
   ```
   或者手动指定：
   ```
   curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.3-stable.tar.xz -o flutter.tar.xz && tar xf flutter.tar.xz && export PATH="$PATH:$PWD/flutter/bin" && cd flutter_codelab && flutter pub get && flutter build web --release --base-href /
   ```

4. **Output Directory**: 
   ```
   flutter_codelab/build/web
   ```

5. **Install Command**: 
   ```
   npm install
   ```
   或者：
   ```
   cd flutter_codelab && flutter pub get
   ```

6. **Node.js Version**: `18.x` 或更高（在 Settings → General 中设置）

## 🚀 部署步骤

### Step 1: 准备配置文件

确保以下文件已提交到 Git：

- ✅ `vercel.json` - Vercel 配置
- ✅ `package.json` - 构建脚本
- ✅ `flutter_codelab/pubspec.yaml` - Flutter 项目配置

### Step 2: 在 Vercel Dashboard 中创建项目

1. 进入 [Vercel Dashboard](https://vercel.com/dashboard)
2. 点击 **"New Project"**
3. 选择 **"Import Git Repository"**
4. 选择 `RickyTan5350/kalmnest`
5. 选择分支 `main`

### Step 3: 配置项目设置

按照上面的配置填写：
- Framework Preset: **Other**
- Root Directory: `./`
- Build Command: `npm run vercel-build`
- Output Directory: `flutter_codelab/build/web`
- Install Command: `npm install`

### Step 4: 添加环境变量

点击 **"Environment Variables"**：

添加：
```
Key: CUSTOM_BASE_URL
Value: https://your-render-backend-url.onrender.com
```

选择应用环境：
- ✅ Production
- ✅ Preview
- ✅ Development（可选）

### Step 5: 部署

1. 点击 **"Deploy"** 按钮
2. 等待构建完成（首次可能需要 10-15 分钟）
3. 查看部署日志确认成功

## ⚠️ 重要注意事项

### 关于 Flutter SDK

Vercel 的默认构建环境**不包含 Flutter SDK**。您有几个选择：

1. **预构建方法（最简单）**:
   - 在本地构建 Flutter Web
   - 提交 `build/web` 目录到 Git
   - 在 Vercel 中配置使用预构建文件

2. **使用 Docker（推荐用于生产）**:
   - 创建 Dockerfile
   - 使用 Vercel 的 Docker 构建功能

3. **使用构建脚本**:
   - 在 Build Command 中下载并安装 Flutter
   - 然后运行构建命令

### 推荐的部署流程

**方案 1: 本地构建 + Vercel 部署（最简单）**

1. 在本地构建：
   ```bash
   cd flutter_codelab
   flutter build web --release --base-href /
   ```

2. 提交构建文件：
   ```bash
   git add flutter_codelab/build/web
   git commit -m "Add pre-built Flutter Web files"
   git push
   ```

3. 在 Vercel 配置：
   - Build Command: `echo "Using pre-built files"`
   - Output Directory: `flutter_codelab/build/web`

**方案 2: 自动构建（需要 GitHub Actions）**

1. 创建 GitHub Actions workflow
2. 自动构建 Flutter Web
3. 提交到特定分支
4. Vercel 从该分支部署

## 🎯 Vercel Dashboard 填写指南

根据您提供的界面，请填写以下内容：

### 基本信息
- **Project Name**: `kalmnest` ✅
- **Framework Preset**: **Other** ✅

### 构建配置

**Root Directory**:
```
./
```

**Build Command**:
```bash
npm run vercel-build
```

**或者如果您想手动指定**:
```bash
curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.3-stable.tar.xz -o flutter.tar.xz && tar xf flutter.tar.xz && export PATH="$PATH:$PWD/flutter/bin" && cd flutter_codelab && flutter pub get && flutter build web --release --base-href /
```

**Output Directory**:
```
flutter_codelab/build/web
```

**Install Command**:
```bash
npm install
```

### 环境变量

点击 **"Environment Variables"** 或 **"Add Environment Variable"**：

添加变量：
- **Key**: `CUSTOM_BASE_URL`
- **Value**: `https://your-render-backend-url.onrender.com`（您的 Render 后端 URL）

**应用环境**:
- ✅ Production
- ✅ Preview
- ✅ Development（可选）

## ✅ 验证部署

部署成功后：

1. **访问部署 URL**: `https://kalmnest.vercel.app`（或您分配的自定义域名）

2. **检查控制台**: 打开浏览器开发者工具（F12）
   - 检查是否有 JavaScript 错误
   - 检查网络请求是否指向正确的后端 URL

3. **测试功能**:
   - 登录功能
   - API 请求
   - 路由导航

## 🔍 故障排除

如果构建失败，检查：

1. **Flutter SDK 未找到**:
   - 使用方案 1（预构建）或更新 Build Command 以下载 Flutter

2. **环境变量未生效**:
   - 确认变量名称：`CUSTOM_BASE_URL`
   - 确认已添加到正确的环境
   - 重新部署以应用变量

3. **构建超时**:
   - Vercel Hobby 计划有构建时间限制
   - 考虑使用预构建方法

## 📞 需要帮助？

如果遇到问题：
1. 查看 Vercel 部署日志
2. 检查 GitHub Actions（如果使用）
3. 参考完整文档：`VERCEL_DEPLOYMENT_GUIDE.md`
