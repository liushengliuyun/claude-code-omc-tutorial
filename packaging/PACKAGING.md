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
- **直连可能被掐（见 §9 坑 2）**：报 `wsasend: Access is denied` 时改走代理 `HTTPS_PROXY=http://127.0.0.1:<FlClash端口> gh release upload ...`，或换一台网络正常的机器上传
- **GitHub Release 附件不支持中文文件名**：上传接口与 PATCH 改名接口都会剥离非 ASCII 字符（`舟氏AI启航包.exe` → `AI.exe`），URL query 带原始 UTF-8 字节直接 400。所以产物名用英文：`ZhouAI-StarterPack.exe`
- 中文 release notes 用 `gh release edit --notes-file <UTF-8文件>`，不要走命令行参数传中文

## 8. 版本更新流程

1. 跑第 2 节三条命令查新版本
2. 有新版 → 下载/复制对应 payload，替换 `payload/` 下文件，改 installer.iss 顶部的 `#define` 版本号与注释里的 SHA256
3. 重新 `ISCC.exe installer.iss`，上传 `--clobber` 覆盖
4. 同步更新本文档第 0 节的版本矩阵和 Release notes

**换机器上传清单**（本机 uploads.github.com 被墙时）：把 `packaging\ZhouAI-StarterPack.exe` 拷到能传的机器上，登好 `gh`，然后：

```bash
gh release upload v1.0 ZhouAI-StarterPack.exe --clobber
gh release edit v1.0 --notes-file release-notes.md   # 中文说明必须走 UTF-8 文件, 命令行传参必乱码
```

## 9. 踩坑记录（2026-10-12 v1.2 修复实录）

**坑 1：隐藏自装静默失败（v1.1 的核心缺陷）**
- 现象：装完 pack 后 `~\.local\bin` 没有 claude.exe、pack 安装目录也没有、PATH 无变化，安装器却照样报成功
- 根因：`[Run]` 以 `runhidden` 执行 `claude.exe install <版本>`，该步骤在部分机器上失败——无任何输出，Inno 也不中断
- 修复：v1.2 改直接落盘 `{app}\bin` + `[Code]` 写 PATH（第 4 节），并编译 claude-only 测试包实测装/卸全链路（落盘 ✓ PATH 注入 ✓ `claude --version` ✓ 卸载后 PATH 条目精确移除、其余条目原样保留 ✓）
- 排查口诀：判断装没装，只看 `claude --version` 通不通；pack 安装目录有没有 claude.exe 不再是判据（v1.2 起有，v1.1 起本就不放）

**坑 2：Release 上传大附件被墙（网络会漂移）**
- `gh release upload` 直连报 `wsasend: Access is denied`（前一天打包时同域名直连还正常）→ 解法见第 7 节
- `git push` 走 github.com：本机直连报 `getsockname() failed with errno 10022`，必须 `git -c http.https://github.com.proxy=http://127.0.0.1:<端口> push`

**坑 3：FlClash 代理端口会漂移**
- 不是固定 7892，本次实测监听 7890；用前 `netstat -ano | findstr FlClashCore的PID` 确认实际端口

**坑 4：Inno 6.4 产物解不开**
- innoextract 1.9 / innounp 0.50 / 7-Zip 26.02 全部无法解包（报 incompatible version）→ 想从已发布的 exe 里取回 payload 没有捷径，构建时的 `payload/` 目录务必本地留档（已被 .gitignore 排除，不会误提交）

**坑 5：claude.exe 的免代理获取通道**
- npm 包 `@anthropic-ai/claude-code` 里的 `bin\claude.exe` 与官方原生二进制一致（2.1.296 实测 SHA256 = `76de74f7…` 与官方 manifest 完全相同），npmmirror 国内直连可下 → downloads.claude.ai 被墙时的首选 payload 来源，全程免代理
