#define MyAppName "Zapret2 Roblox Kontrol Merkezi"
#define MyAppVersion "1.0.1"
#define MyAppPublisher "cem89"
#define MyAppURL "https://github.com/cem89/zapret2-v1.0.1"
#define MyAppExeName "zapret2_kontrol_merkezi.exe"
#define MyAppAssocName MyAppName + " Uygulamasi"
#define MyAppDir ".."

[Setup]
AppId={{C8B485E6-4F8A-43D6-9D7F-2B3A2A7F0C11}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
LicenseFile=
PrivilegesRequired=admin
OutputDir=C:\outputs
OutputBaseFilename=zapret2-roblox-inno-setup
SetupIconFile={#MyAppDir}\nfq2\windows\res\winws.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
WizardSizePercent=125
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\nfq2\windows\res\winws.ico

[Languages]
Name: "turkish"; MessagesFile: "compiler:Languages\Turkish.isl"

[Tasks]
Name: "desktopicon"; Description: "Masaustu kisayolu olustur"; GroupDescription: "Ek gorevler:"; Flags: checkedonce

[Files]
Source: "{#MyAppDir}\binaries\windows-x86_64\*"; DestDir: "{app}\binaries\windows-x86_64"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#MyAppDir}\files\roblox-hostlist.txt"; DestDir: "{app}\files"; Flags: ignoreversion
Source: "{#MyAppDir}\lua\*"; DestDir: "{app}\lua"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#MyAppDir}\nfq2\windows\res\winws.ico"; DestDir: "{app}\nfq2\windows\res"; Flags: ignoreversion
Source: "{#MyAppDir}\README.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MyAppDir}\roblox-bypass.conf"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MyAppDir}\start_roblox_dpi_bypass.cmd"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MyAppDir}\start_roblox_dpi_bypass.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MyAppDir}\stop_roblox_dpi_bypass.cmd"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MyAppDir}\test_roblox_reachability.cmd"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MyAppDir}\test_roblox_reachability.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MyAppDir}\zapret2-roblox-common.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MyAppDir}\zapret2-roblox-api.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MyAppDir}\zapret2_kontrol_merkezi.cmd"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MyAppDir}\zapret2_kontrol_merkezi.vbs"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MyAppDir}\zapret2_kontrol_merkezi.exe"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; IconFilename: "{app}\nfq2\windows\res\winws.ico"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Tasks: desktopicon; IconFilename: "{app}\nfq2\windows\res\winws.ico"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{#MyAppName} uygulamasini baslat"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "{sys}\cmd.exe"; Parameters: "/c taskkill /F /IM ""{#MyAppExeName}"" /T >nul 2>nul & exit /b 0"; Flags: runhidden; RunOnceId: "StopControlCenter"
Filename: "{sys}\cmd.exe"; Parameters: "/c taskkill /F /IM ""winws2.exe"" /T >nul 2>nul & exit /b 0"; Flags: runhidden; RunOnceId: "StopWinws2"
Filename: "{sys}\cmd.exe"; Parameters: "/c sc stop WinDivert >nul 2>nul & exit /b 0"; Flags: runhidden; RunOnceId: "StopWinDivert"
Filename: "{sys}\cmd.exe"; Parameters: "/c sc delete WinDivert >nul 2>nul & exit /b 0"; Flags: runhidden; RunOnceId: "DeleteWinDivert"

[UninstallDelete]
Type: files; Name: "{app}\winws-roblox.log"
Type: files; Name: "{app}\winws-roblox.err"
Type: files; Name: "{app}\*.log"
Type: files; Name: "{app}\*.err"
Type: dirifempty; Name: "{app}"
