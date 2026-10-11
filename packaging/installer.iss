; ============================================================
; 舟氏AI启航包 v1.1 — Claude Code + Warp + CC Switch 离线一键安装
; 由 Inno Setup 6 编译 (ISCC.exe installer.iss)
; 组件版本与校验值见 PACKAGING.md
; ============================================================

#define MyAppName "舟氏AI启航包"
#define MyAppNameEn "ZhouAI-StarterPack"
#define MyAppVersion "1.1"
#define ClaudeVersion "2.1.296"
#define WarpVersion "v0.2026.09.30.08.29.stable_01"
#define CcswitchVersion "4.0.8"

[Setup]
AppId={{D4E7A1B3-8F2C-4E6A-9D5B-1C3F7E2A4B6D}}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} v{#MyAppVersion}
; AppName 单独定义以保证卸载列表显示中文名
AppName={#MyAppName}
AppPublisher=舟氏
DefaultDirName={localappdata}\{#MyAppNameEn}
CreateAppDir=yes
DirExistsWarning=no
DisableProgramGroupPage=yes
; 普通用户权限,无需管理员
PrivilegesRequired=lowest
OutputDir=.
OutputBaseFilename=ZhouAI-StarterPack
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ShowLanguageDialog=no
UninstallDisplayName={#MyAppName}
UninstallDisplayIcon={app}\unins000.exe

[Languages]
Name: "zh"; MessagesFile: "ChineseSimplified.isl"

[Files]
; --- Claude Code 2.1.296 (官方原生二进制, 离线自安装, SHA256: 76de74f7694a5bdc03378a5f837c9e132827bf004c98c276bc4e9094ff06769a) ---
Source: "payload\claude.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall
; --- Warp v0.2026.09.30.08.29.stable_01 官方安装器 ---
Source: "payload\WarpSetup.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall
; --- CC Switch v4.0.8 官方 MSI ---
Source: "payload\CC-Switch-v4.0.8-Windows.msi"; DestDir: "{tmp}"; Flags: deleteafterinstall
; --- 教程快捷方式到桌面 ---
Source: "payload\舟氏AI启航包-教程.url"; DestDir: "{autodesktop}"; Flags: ignoreversion

[Run]
; 1) Claude Code 原生二进制自安装(已实测:纯离线,不访问 downloads.claude.ai)
Filename: "{tmp}\claude.exe"; Parameters: "install {#ClaudeVersion}"; Flags: runhidden waituntilterminated; StatusMsg: "正在安装 Claude Code {#ClaudeVersion} (离线自包含,无需联网)..."
; 2) Warp 静默安装 (Inno 静默参数)
Filename: "{tmp}\WarpSetup.exe"; Parameters: "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"; Flags: waituntilterminated; StatusMsg: "正在安装 Warp 终端..."
; 3) CC Switch 静默安装 (MSI /qb 带进度,必要时触发 UAC)
Filename: "msiexec.exe"; Parameters: "/i ""{tmp}\CC-Switch-v4.0.8-Windows.msi"" /qb /norestart"; Flags: waituntilterminated; StatusMsg: "正在安装 CC Switch..."

[UninstallDelete]
; 安装器只做部署,卸载仅清理包自身的安装目录与桌面快捷方式(不卸载三个软件)
Type: filesandordirs; Name: "{app}"

[Icons]
Name: "{autoprograms}\{#MyAppName}\教程 - 舟氏AI启航包"; Filename: "https://liushengliuyun.github.io/claude-code-omc-tutorial/"
