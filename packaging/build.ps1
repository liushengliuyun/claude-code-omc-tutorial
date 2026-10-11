# ============================================================
# 舟氏AI启航包 一键构建脚本 (build.ps1)
# 用法: powershell -ExecutionPolicy Bypass -File build.ps1
# 前提: gh CLI 已登录; Inno Setup 6 已装; 本机已装最新 Claude Code (原生安装)
# 可选: 需要现下 claude.exe 时先设 $env:HTTPS_PROXY
# ============================================================
param(
    [string]$ClaudeVersion  = "2.1.296",
    [string]$WarpVersion    = "v0.2026.09.30.08.29.stable_01",
    [string]$CcswitchVersion = "4.0.8"
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$root    = $PSScriptRoot
$payload = Join-Path $root 'payload'
New-Item -ItemType Directory -Force -Path $payload | Out-Null

# ---------- 1. 版本提示 ----------
Write-Host '== 查询最新版本(直连) ==' -ForegroundColor Cyan
$npmLatest = (Invoke-RestMethod 'https://registry.npmmirror.com/@anthropic-ai/claude-code/latest').version
$warpList  = gh api repos/microsoft/winget-pkgs/contents/manifests/w/Warp/Warp --jq '.[].name' 2>$null
$warpLatest = ($warpList | Sort-Object -Version | Select-Object -Last 1)
$ccLatest  = (gh api repos/farion1231/cc-switch/releases/latest --jq '.tag_name') -replace '^v',''
Write-Host ("Claude Code latest : " + $npmLatest)
Write-Host ("Warp latest        : " + $warpLatest)
Write-Host ("CC Switch latest   : " + $ccLatest)

# ---------- 2. Claude Code ----------
Write-Host '== Claude Code ==' -ForegroundColor Cyan
$claudeBin = Join-Path $env:USERPROFILE '.local\bin\claude.exe'
if (Test-Path $claudeBin) {
    $localVer = (& $claudeBin --version) -replace ' \(.*\)',''
    if ($localVer -eq $ClaudeVersion) {
        Copy-Item $claudeBin (Join-Path $payload 'claude.exe') -Force
        Write-Host "已从本机复制 claude.exe ($localVer)"
    } else {
        Write-Warning "本机版本 $localVer != 目标 $ClaudeVersion, 请更新本机 claude 或改 -ClaudeVersion 后重跑"
        exit 1
    }
} else {
    Write-Warning "本机无原生安装, 走代理下载 $ClaudeVersion ..."
    $manifest = Invoke-RestMethod "https://downloads.claude.ai/claude-code-releases/$ClaudeVersion/manifest.json"
    Invoke-WebRequest "https://downloads.claude.ai/claude-code-releases/$ClaudeVersion/win32-x64/claude.exe" -OutFile (Join-Path $payload 'claude.exe')
    $sum = (Get-FileHash (Join-Path $payload 'claude.exe') -Algorithm SHA256).Hash.ToLower()
    if ($sum -ne $manifest.platforms.'win32-x64'.checksum) { throw 'claude.exe 校验失败!' }
    Write-Host '下载完成且校验通过'
}

# ---------- 3. Warp ----------
Write-Host '== Warp ==' -ForegroundColor Cyan
$warpUrl = "https://app.warp.dev/download/windows?version=$WarpVersion&arch=x86_64"
& curl.exe -sSL $warpUrl -o (Join-Path $payload 'WarpSetup.exe')
Write-Host ("WarpSetup.exe : " + (Get-Item (Join-Path $payload 'WarpSetup.exe')).Length + " B")

# ---------- 4. CC Switch ----------
Write-Host '== CC Switch ==' -ForegroundColor Cyan
& gh release download "v$CcswitchVersion" --repo farion1231/cc-switch `
    --pattern "CC-Switch-v$CcswitchVersion-Windows.msi" --dir $payload --clobber
Write-Host ("MSI : " + (Get-Item (Join-Path $payload ("CC-Switch-v$CcswitchVersion-Windows.msi"))).Length + " B")

# ---------- 5. 教程快捷方式 ----------
$url = Join-Path $payload '舟氏AI启航包-教程.url'
@'
[InternetShortcut]
URL=https://liushengliuyun.github.io/claude-code-omc-tutorial/
IconIndex=0
'@ | Set-Content -Encoding UTF8 $url

# ---------- 6. 补 .iss 的 UTF-8 BOM ----------
$iss = Join-Path $root 'installer.iss'
$bytes = [System.IO.File]::ReadAllBytes($iss)
if (-not ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)) {
    [System.IO.File]::WriteAllBytes($iss, ([byte[]](0xEF,0xBB,0xBF)) + $bytes)
    Write-Host '已补 UTF-8 BOM'
}

# ---------- 7. 编译 ----------
Write-Host '== Inno Setup 编译 ==' -ForegroundColor Cyan
$iscc = Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe'
if (-not (Test-Path $iscc)) { $iscc = 'C:\Program Files (x86)\Inno Setup 6\ISCC.exe' }
& $iscc $iss
if ($LASTEXITCODE -ne 0) { throw "ISCC 编译失败 (exit $LASTEXITCODE)" }

$out = Join-Path $root 'ZhouAI-StarterPack.exe'
Write-Host ''
Write-Host ("构建完成: " + $out + " (" + [math]::Round((Get-Item $out).Length/1MB,1) + " MB)")
Write-Host '上传命令: gh release upload v1.0 "ZhouAI-StarterPack.exe" --clobber'
