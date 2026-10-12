# 舟氏AI启航包 · 打包过程完整文档

> 本文记录「舟氏AI启航包」的完整打包流程，照着做即可复现。
>
> **免代理原则：** 查版本、下载 Warp / CC Switch、编译、上传 GitHub Release 全部国内直连可用；只有获取 claude.exe（本机版本落后时）才需要代理。
>
> **当前版本矩阵（2026-10-12 打包 v1.2）：**
>
> | 组件 | 版本 |
> |---|---|
> | Claude Code | 2.1.296 |
> | Warp | v0.2026.09.30.08.29.stable_01 |
> | CC Switch | 4.0.8 |

## 0. 为什么需要离线启航包

2026-10-11 国内直连实测：

| 域名 | 直连结果 |
|---|---|
| `claude.ai/install.ps1` | ❌ 302 到 `app-unavailable-in-region`（区域封锁） |
| `downloads.claude.ai` | ❌ 直连超时 |
| `app.warp.dev` | ✅ 直连 3 MB/s |
| `api.github.com` | ✅ gh CLI 全功能直连 |
| `registry.npmmirror.com` | ✅ 直连 |
| `gh-proxy.com` | ✅ 可加速 GitHub Release 下载 |

Claude Code 官方原生安装（`irm https://claude.ai/install.ps1 | iex`）在国内不可用，所以必须把二进制离线捆绑进安装包。

## 1. 准备

- Inno Setup 6（含命令行编译器 `ISCC.exe`）
- gh CLI（已登录，直连可用）

## 2. 查最新版本（全部直连）

```bash
# Claude Code 最新版（直连 npmmirror）
curl -s https://registry.npmmirror.com/@anthropic-ai/claude-code/latest | grep -o '"version":"[^"]*"'

# Warp 最新 stable（winget 清单目录，最后一个即最新）
gh api repos/microsoft/winget-pkgs/contents/manifests/w/Warp/Warp --jq '.[] | .name' | sort -V | tail -1

# CC Switch 最新版
gh api repos/farion1231/cc-switch/releases/latest --jq .tag_name
```

## 3. 获取 payload（三个文件）

### 3.1 Claude Code（约 260 MB）

**路径 A（推荐，零下载）：从本机已装的原生安装复制**

- 位置：`%USERPROFILE%\.local\bin\claude.exe`
- 前提：本机版本 = 第 2 步查到的最新版（对比 `claude --version`）
- **必须校验哈希**（manifest 很小，走代理也秒回）：

```bash
# 官方校验值
HTTPS_PROXY=http://127.0.0.1:<漂移端口> curl -s \
  https://downloads.claude.ai/claude-code-releases/<版本>/manifest.json \
  | grep -A3 '"win32-x64"'

# 本地二进制哈希
certutil -hashfile "%USERPROFILE%\.local\bin\claude.exe" SHA256
```

本次实测两者完全一致：`76de74f7694a5bdc03378a5f837c9e132827bf004c98c276bc4e9094ff06769a`。

**路径 B：代理下载原始二进制**

```bash
HTTPS_PROXY=http://127.0.0.1:<漂移端口> curl -sL \
  "https://downloads.claude.ai/claude-code-releases/<版本>/win32-x64/claude.exe" -o payload/claude.exe
```

### 3.2 Warp（约 135 MB）

官方直链（版本固定），国内直连快：

```bash
curl -sSL "https://app.warp.dev/download/windows?version=<Warp版本>&arch=x86_64" \
  -o payload/WarpSetup.exe
```

- 实测直连 3 MB/s、约 45 秒下完 134 MB；**同一 URL 走 FlClash 代理反而只有 1.4 KB/s**——warp 的 CDN 国内不需要代理。
- 产物是**完整安装器**（134 MB），不是引导器，离线可装；winget 清单标注 `InstallerType: inno`，二进制内已确认 Inno 标记。

### 3.3 CC Switch（约 16 MB）

```bash
gh release download v4.0.8 --repo farion1231/cc-switch \
  --pattern "CC-Switch-v4.0.8-Windows.msi" --dir payload/
```

### 3.4 Inno 简体中文语言包

Inno 默认不带简中，从官方 issrc 仓库取（直连 gh api）：

```bash
SHA=$(gh api "repos/jrsoftware/issrc/git/trees/is-6_6_1?recursive=1" \
  --jq '.tree[] | select(.path=="Files/Languages/Unofficial/ChineseSimplified.isl") | .sha')
gh api repos/jrsoftware/issrc/git/blobs/$SHA --jq '.content' | base64 -d > ChineseSimplified.isl
```

### 3.5 教程快捷方式

创建 `payload\舟氏AI启航包-教程.url`：

```ini
[InternetShortcut]
URL=https://liushengliuyun.github.io/claude-code-omc-tutorial/
IconIndex=0
```

## 4. 部署原理（核心，已实测）

| 组件 | 部署方式（Inno `[Files]` / `[Run]` 段） | 说明 |
|---|---|---|
| Claude Code | **直接落盘** `{app}\bin\claude.exe` + `[Code]` 把 `{app}\bin` 追加进用户 PATH | 二进制即整个程序，落盘即用；卸载时自动移除 PATH 条目 |
| Warp | `WarpSetup.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART` | Inno 标准静默参数，winget 清单 `InstallerType: inno` |
| CC Switch | `msiexec /i <msi> /qb /norestart` | 标准 MSI；选 `/qb` 而非 `/qn`：基本 UI 带进度条，必要时能弹 UAC |

安装顺序：Claude Code（文件直拷）→ Warp → CC Switch，全部静默，装完即用。Warp / CC Switch 的 payload 走 `{tmp}` 且 `deleteafterinstall`，装完自动清理临时目录；claude.exe 持久保留在安装目录。

**v1.1 → v1.2 变更（为什么放弃「claude.exe install 自装」）：**

- v1.1 用 `[Run]` 隐藏执行 `claude.exe install <版本>` 让二进制自装进 `%USERPROFILE%\.local\bin`。实测在部分机器上该步骤**静默失败**（`runhidden` 无任何输出，Inno 不中断、照样显示安装成功），且 pack 安装目录里看不到 claude.exe，用户无法判断装没装上；
- v1.2 起 claude.exe 直接安装到本包目录 `{localappdata}\ZhouAI-StarterPack\bin\claude.exe`，并把该目录**追加**进用户 PATH（条目级精确匹配防重复；`ChangesEnvironment=yes` 让安装/卸载自动广播 `WM_SETTINGCHANGE`，免重启生效）；
- 卸载时按条目移除 PATH 中的 `{app}\bin` 并重建（顺带清理空段），其余 PATH 内容原样保留；
- 代价与取舍：`claude update` 自更新装进 `~\.local\bin` 时，PATH 中两者并存——本包目录条目**追加在末尾**，不遮蔽官方安装；更新本包覆盖即可升级内置版本。

## 5. Inno 脚本要点（installer.iss）

- **`.iss 必须 UTF-8 with BOM`**——含中文字符串时缺 BOM 会解析异常。Write 工具写文件不带 BOM，写完必须手动补：


```bash
printf '\xef\xbb\xbf' > /tmp/bom && cat installer.iss >> /tmp/bom && mv /tmp/bom installer.iss
```

- `PrivilegesRequired=lowest`：普通用户权限，无需管理员
- `ChangesEnvironment=yes` + `[Code]`：安装时把 `{app}\bin` 追加进 `HKCU\Environment\Path`（已含同条目则跳过），卸载时按条目移除；Inno 自动广播环境变量变更
- `Compression=lzma2/max` + `SolidCompression=yes`：411 MB payload → 236 MB 产物，48 秒编完
- `ShowLanguageDialog=no` + `[Languages]` 只留 zh → 全中文安装界面
- 桌面放教程快捷方式（.url），开始菜单留教程入口
- 卸载器只清理包自身目录与快捷方式，**不卸载三个软件**（它们是独立应用，各自可卸载）

## 6. 构建

```bash
cd /d/ZhouAI-StarterPack-build
"/c/Users/Admin/AppData/Local/Programs/Inno Setup 6/ISCC.exe" installer.iss
# → Successful compile (48 秒) → ZhouAI-StarterPack.exe (236,298,712 B)
```

## 7. 上传 GitHub Release


```bash
gh release upload v1.0 "D:\ZhouAI-StarterPack-build\ZhouAI-StarterPack.exe" --clobber
```

- 上传走 `uploads.github.com` **直连且快**（214 MB 约 1 分钟）
- **GitHub Release 附件不支持中文文件名**：上传接口与 PATCH 改名接口都会剥离非 ASCII 字符（`舟氏AI启航包.exe` → `AI.exe`），URL query 带原始 UTF-8 字节直接 400。所以产物名用英文：`ZhouAI-StarterPack.exe`
- 中文 release notes 用 `gh release edit --notes-file <UTF-8文件>`，不要走命令行参数传中文

## 8. 版本更新流程

1. 跑第 2 节三条命令查新版本
2. 有新版 → 下载/复制对应 payload，替换 `payload/` 下文件，改 installer.iss 顶部的 `#define` 版本号与注释里的 SHA256
3. 重新 `ISCC.exe installer.iss`，上传 `--clobber` 覆盖
4. 同步更新本文档第 0 节的版本矩阵和 Release notes
