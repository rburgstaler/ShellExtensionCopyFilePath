unit RestartManagerUtils;

interface

uses
  Windows;

type
TPKernelRegisterApplicationRestart = function(lpCmdLine: PWideChar; dwFlags: DWORD): DWORD; stdcall;

var
  WinMajorVersion, WinMinorVersion: Cardinal;
  RegisterApplicationRestart: TPKernelRegisterApplicationRestart;

procedure DoRegisterApplicationRestart(AParams: String);

implementation

procedure DoRegisterApplicationRestart(AParams: String);
var
  Ver: TOSVERSIONINFO;
  Kernel32Dll: HMODULE;
begin
  Ver.dwOSVersionInfoSize := SizeOf(TOSVERSIONINFO);
  GetVersionEx(Ver);
  WinMajorVersion := Ver.dwMajorVersion;
  WinMinorVersion := Ver.dwMinorVersion;


  if (Ver.dwPlatformID = VER_PLATFORM_WIN32_NT) then
  begin
    Kernel32Dll := LoadLibrary('Kernel32.DLL');
    if (0 <> Kernel32Dll) then
    begin
      if (WinMajorVersion > 5) then
      begin
        // Register with the Vista+ Restart Manager:
        @RegisterApplicationRestart := GetProcAddress(Kernel32Dll, 'RegisterApplicationRestart');
        if @RegisterApplicationRestart <> nil then
        begin
            if RegisterApplicationRestart(PWideChar(AParams), 8 { RESTART_NO_REBOOT } ) = S_OK then
        end;
      end;
    end;
  end;
end;

end.
