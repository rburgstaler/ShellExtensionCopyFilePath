#define cAppVersion GetFileVersion(AddBackslash(SourcePath) + "..\bin\Win64\ShellExtCopyFilePath.dll")

[Setup]
AppName=ShellExtCopyFilePath
AppVersion={#cAppVersion}
DefaultDirName={pf}\ShellExtCopyFilePath
DefaultGroupName=ShellExtCopyFilePath
UninstallDisplayIcon={app}\UninstallShellExtCopyFilePath.exe
Compression=lzma2
SolidCompression=yes
OutputDir=.\
OutputBaseFilename=InstallShellExtCopyFilePath_x64
ArchitecturesInstallIn64BitMode=x64 ia64

[Types]
Name: "custom"; Description: "Select components"; Flags: iscustom

[Components]
Name: RestartExplorer; Description: "Restart Explorer"; Flags: disablenouninstallwarning; Types: custom

[Files]
Source: "..\bin\Win64\ShellExtCopyFilePath.dll"; DestDir: "{app}"; Flags: ignoreversion replacesameversion regserver

[Run]
Filename: "taskkill"; Parameters: "/F /IM Explorer.exe"; Description: "Restarting Explorer"; Components: RestartExplorer;
Filename: "{win}\Explorer.exe"; Description: "Starting Explorer"; Flags: nowait; Components: RestartExplorer;

