; ============================================================
; 舟氏AI启航包 v1.2 — Claude Code + Warp + CC Switch 离线一键安装
; 由 Inno Setup 6 编译 (ISCC.exe installer.iss)
; 组件版本与校验值见 PACKAGING.md
;
; v1.2 变更: Claude Code 不再走「claude.exe install 隐藏自装」
; (该步骤 runhidden 无输出, 在部分机器上静默失败, 且 pack 安装
; 目录里看不到 claude.exe 无法排查)。改为直接落盘
; {app}\bin\claude.exe, 并由 [Code] 把 {app}\bin 追加进用户 PATH
; (卸载时自动移除该条目)。安装目录可见、可验证。
; ============================================================

#define MyAppName "舟氏AI启航包"
#define MyAppNameEn "ZhouAI-StarterPack"
#define MyAppVersion "1.2"
#define ClaudeVersion "2.1.296"
#define WarpVersion "v0.2026.09.30.08.29.stable_01"
#define CcswitchVersion "4.0.8"

[Setup]
AppId={{D4E7A1B3-8F2C-4E6A-9D5B-1C3F7E2A4B6D}
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
; 安装/卸载会修改用户环境变量(PATH), 让系统广播 WM_SETTINGCHANGE 免重启生效
ChangesEnvironment=yes
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
; --- Claude Code 2.1.296 (官方原生二进制, SHA256: 76de74f7694a5bdc03378a5f837c9e132827bf004c98c276bc4e9094ff06769a) ---
; 直接安装到 {app}\bin (持久保留, 由 PATH 指向), 不再依赖自装
Source: "payload\claude.exe"; DestDir: "{app}\bin"; Flags: ignoreversion
; --- Warp v0.2026.09.30.08.29.stable_01 官方安装器 ---
Source: "payload\WarpSetup.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall
; --- CC Switch v4.0.8 官方 MSI ---
Source: "payload\CC-Switch-v4.0.8-Windows.msi"; DestDir: "{tmp}"; Flags: deleteafterinstall
; --- 教程快捷方式到桌面 ---
Source: "payload\舟氏AI启航包-教程.url"; DestDir: "{autodesktop}"; Flags: ignoreversion

[Run]
; Claude Code 已由 [Files] 直接落盘 {app}\bin, 无需安装命令
; 1) Warp 静默安装 (Inno 静默参数)
Filename: "{tmp}\WarpSetup.exe"; Parameters: "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"; Flags: waituntilterminated; StatusMsg: "正在安装 Warp 终端..."
; 2) CC Switch 静默安装 (MSI /qb 带进度,必要时触发 UAC)
Filename: "msiexec.exe"; Parameters: "/i ""{tmp}\CC-Switch-v4.0.8-Windows.msi"" /qb /norestart"; Flags: waituntilterminated; StatusMsg: "正在安装 CC Switch..."

[UninstallDelete]
; 安装器只做部署,卸载仅清理包自身的安装目录与桌面快捷方式(不卸载三个软件)
Type: filesandordirs; Name: "{app}"

[Icons]
Name: "{autoprograms}\{#MyAppName}\教程 - 舟氏AI启航包"; Filename: "https://liushengliuyun.github.io/claude-code-omc-tutorial/"

[Code]
// ===== 用户 PATH 管理: 安装时追加 / 卸载时移除 {app}\bin =====
// 追加前按条目精确匹配(忽略大小写)防重复; 卸载重建 PATH 时顺带去掉空段

function BinPath(): String;
begin
  Result := ExpandConstant('{app}') + '\bin';
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  BinDir, OldPath: String;
begin
  if CurStep = ssPostInstall then
  begin
    BinDir := BinPath();
    if RegQueryStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', OldPath) then
    begin
      // 已含同一条目则不重复追加
      if Pos(';' + LowerCase(BinDir) + ';', ';' + LowerCase(OldPath) + ';') > 0 then Exit;
      RegWriteStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', OldPath + ';' + BinDir);
    end
    else
      RegWriteStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', BinDir);
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  BinDir, OldPath, NewPath, Entry: String;
  P, Start: Integer;
begin
  if CurUninstallStep = usUninstall then
  begin
    BinDir := LowerCase(BinPath());
    if RegQueryStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', OldPath) then
    begin
      NewPath := '';
      Start := 1;
      repeat
        P := Pos(';', Copy(OldPath, Start, Length(OldPath)));
        if P > 0 then
          Entry := Copy(OldPath, Start, P - 1)
        else
          Entry := Copy(OldPath, Start, Length(OldPath));
        if (Entry <> '') and (LowerCase(Entry) <> BinDir) then
        begin
          if NewPath <> '' then NewPath := NewPath + ';';
          NewPath := NewPath + Entry;
        end;
        Start := Start + P;
      until P = 0;
      if NewPath <> '' then
        RegWriteStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', NewPath)
      else
        RegDeleteValue(HKEY_CURRENT_USER, 'Environment', 'Path');
    end;
  end;
end;
