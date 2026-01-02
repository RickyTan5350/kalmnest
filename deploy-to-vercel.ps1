# Flutter Web 部署到 Vercel 脚本
# 使用 Vercel CLI 部署到现有仓库

Write-Host "🚀 开始部署 Flutter Web 到 Vercel..." -ForegroundColor Green
Write-Host ""

# 步骤 1: 检查 Vercel CLI
Write-Host "📦 检查 Vercel CLI..." -ForegroundColor Yellow
$vercelInstalled = Get-Command vercel -ErrorAction SilentlyContinue
if (-not $vercelInstalled) {
    Write-Host "⚠️  Vercel CLI 未安装，正在安装..." -ForegroundColor Yellow
    npm i -g vercel
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ 安装失败！请手动运行: npm i -g vercel" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Vercel CLI 安装成功" -ForegroundColor Green
} else {
    Write-Host "✅ Vercel CLI 已安装" -ForegroundColor Green
}
Write-Host ""

# 步骤 2: 构建 Flutter Web
Write-Host "🔨 构建 Flutter Web (release 模式)..." -ForegroundColor Yellow
Set-Location flutter_codelab
flutter build web --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 构建失败！" -ForegroundColor Red
    exit 1
}
Write-Host "✅ 构建成功" -ForegroundColor Green
Write-Host ""

# 步骤 3: 进入构建目录
Set-Location build/web

# 步骤 4: 部署到 Vercel
Write-Host "🚀 部署到 Vercel..." -ForegroundColor Yellow
Write-Host "提示: 如果是首次部署，Vercel 会询问一些问题" -ForegroundColor Cyan
Write-Host "  - Set up and deploy? → Y" -ForegroundColor Gray
Write-Host "  - Which scope? → 选择您的账号" -ForegroundColor Gray
Write-Host "  - Link to existing project? → N (创建新项目)" -ForegroundColor Gray
Write-Host "  - Project name? → kalmnest-frontend (或您喜欢的名字)" -ForegroundColor Gray
Write-Host "  - Directory? → ./ (当前目录)" -ForegroundColor Gray
Write-Host ""

vercel --prod

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ 部署成功！" -ForegroundColor Green
    Write-Host "📝 您的应用现在应该已经上线了" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "💡 提示:" -ForegroundColor Yellow
    Write-Host "  - 在 Vercel Dashboard 可以查看部署详情" -ForegroundColor Gray
    Write-Host "  - 可以在项目设置中连接 GitHub 仓库以启用自动部署" -ForegroundColor Gray
} else {
    Write-Host ""
    Write-Host "❌ 部署失败！请检查错误信息" -ForegroundColor Red
    exit 1
}

