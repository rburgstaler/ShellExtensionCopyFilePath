unit CM;
 
interface
 
uses
  Windows, ActiveX, ComObj, ShlObj, Dialogs, Forms;
 
type
  TContextMenu = class(TComObject, IShellExtInit, IContextMenu)
  private
    fPaths: String;
  protected
    { IShellExtInit }
    function IShellExtInit.Initialize = SEIInitialize; // Avoid compiler warning
    function SEIInitialize(pidlFolder: PItemIDList; lpdobj: IDataObject;
      hKeyProgID: HKEY): HResult; stdcall;
    { IContextMenu }
    function QueryContextMenu(Menu: HMENU; indexMenu, idCmdFirst, idCmdLast,
      uFlags: UINT): HResult; stdcall;
    function InvokeCommand(var lpici: TCMInvokeCommandInfo): HResult; stdcall;
    function GetCommandString(idCmd, uType: UINT; pwReserved: PUINT;
      pszName: LPSTR; cchMax: UINT): HResult; stdcall;
  end;


const
  Class_ContextMenu: TGUID = '{F3026062-4D7E-4638-9A6B-3B2CCAC3FCBB}';
  cVerbCopyFileFullPath = 0;
  cVerbCopyFileName = 1;
  cVerbAppendCopyFileFullPath = 2;
  cVerbAppendCopyFileName = 3;
implementation

uses ComServ, SysUtils, ShellApi, Registry, ClipBrd, Classes;

var
  gAllPaths: String;

function TContextMenu.SEIInitialize(pidlFolder: PItemIDList; lpdobj: IDataObject;
  hKeyProgID: HKEY): HResult;
var
  StgMedium: TStgMedium;
  FormatEtc: TFormatEtc;
  lFileName: array[0..MAX_PATH] of Char;
  lTemp: String;
  lCount: Integer;
  x: Integer;
begin
  // Refuses the call if lpdobj is Nil.
  if (lpdobj = nil) then
  begin
    Result := E_INVALIDARG;
    Exit;
  end;

  with FormatEtc do
  begin
    cfFormat := CF_HDROP;
    ptd      := nil;
    dwAspect := DVASPECT_CONTENT;
    lindex   := -1;
    tymed    := TYMED_HGLOBAL;
  end;

  Result := lpdobj.GetData(FormatEtc, StgMedium);
  if Failed(Result) then Exit;

  // If only one file is rightclicked, it reads the filename and stores it in
  // FFileName. Otherwise it refuses the call.
  lCount:=DragQueryFile(StgMedium.hGlobal, $FFFFFFFF, nil, 0);
  if (lCount > 0) then
  begin
    for x:=0 to (lCount-1) do
    begin
      DragQueryFile(StgMedium.hGlobal, x, lFileName, SizeOf(lFileName));
      lTemp:=lFileName;
      if DirectoryExists(lTemp) then lTemp:=IncludeTrailingPathDelimiter(lTemp);
      fPaths:=fPaths+lTemp;
      if x<(lCount-1) then fPaths:=fPaths+#13#10;
    end;
    Result := NOERROR;
  end
  else
  begin
    lFileName[0] := #0;
    Result := E_FAIL;
  end;

  ReleaseStgMedium(StgMedium);
end;
 
function TContextMenu.QueryContextMenu(Menu: HMENU; indexMenu, idCmdFirst,
          idCmdLast, uFlags: UINT): HResult;
begin
   Result := 0;



  if ((uFlags and $0000000F) = CMF_NORMAL) or ((uFlags and CMF_EXPLORE) <> 0) then
    begin
       // Add item in context menu
       InsertMenu(Menu, indexMenu, MF_SEPARATOR or MF_BYPOSITION, idCmdFirst,'');
       InsertMenu(Menu, indexMenu, MF_STRING or MF_BYPOSITION, idCmdFirst+cVerbAppendCopyFileName, PChar('Append file name(s)..'));
       InsertMenu(Menu, indexMenu, MF_STRING or MF_BYPOSITION, idCmdFirst+cVerbAppendCopyFileFullPath, PChar('Append file path(s)..'));
       InsertMenu(Menu, indexMenu, MF_STRING or MF_BYPOSITION, idCmdFirst+cVerbCopyFileName, PChar('Copy file name(s)..'));
       InsertMenu(Menu, indexMenu, MF_STRING or MF_BYPOSITION, idCmdFirst+cVerbCopyFileFullPath, PChar('Copy file path(s)..'));
       InsertMenu(Menu, indexMenu, MF_SEPARATOR or MF_BYPOSITION, idCmdFirst,'');
       // Returns number of items added
       Result := 6;
    end;
end;

function ExtractFileNames(APaths: String): String;
var
  lList: TStringList;
  x: Integer;
  lStr: String;
begin
  Result:='';
  lList:=TStringList.Create;
  try
    lList.Text:=APaths;
    for x:=0 to (lList.Count-1) do
    begin
      lStr:=lList[x];
      lStr:=ExcludeTrailingPathDelimiter(lStr);
      if Trim(lStr)='' then Continue;
      Result:=Result+ExtractFileName(lStr);
      if x<(lList.Count-1) then Result:=Result+#13#10;
    end;
  finally
    lList.Free;
  end;
end;

function TContextMenu.InvokeCommand(var lpici: TCMInvokeCommandInfo): HResult;
var H: THandle;
    PrevDir: string;
begin
  Result := E_FAIL;
  // Exclude call from another function
  if (HiWord(Integer(lpici.lpVerb)) <> 0) then
  begin
    Exit;
  end;

  // Execute command specified by lpici.lpVerb
  case LoWord(lpici.lpVerb) of
    cVerbCopyFileFullPath:
    begin
      Clipboard.AsText:=fPaths;
      gAllPaths:=fPaths;
    end;
    cVerbCopyFileName:
    begin
      Clipboard.AsText:=ExtractFileNames(fPaths);
      gAllPaths:=fPaths;
    end;
    cVerbAppendCopyFileFullPath:
    begin
      if gAllPaths<>'' then gAllPaths:=gAllPaths+#13#10;
      gAllPaths:=gAllPaths+fPaths;
      Clipboard.AsText:=gAllPaths;
    end;
    cVerbAppendCopyFileName:
    begin
      if gAllPaths<>'' then gAllPaths:=gAllPaths+#13#10;
      gAllPaths:=gAllPaths+fPaths;
      Clipboard.AsText:=ExtractFileNames(gAllPaths);
    end
    else Result := E_INVALIDARG;
  end;
end;

function TContextMenu.GetCommandString(idCmd, uType: UINT; pwReserved: PUINT;
  pszName: LPSTR; cchMax: UINT): HRESULT;
begin
  Result := E_INVALIDARG;
  if (uType = GCS_HELPTEXT) then
  begin
    Result := NOERROR;
    case idCmd of
      cVerbCopyFileFullPath: StrCopy(pszName, PAnsiChar('Copy the selected filepath(s) to the clipboard..'));
      cVerbCopyFileName: StrCopy(pszName, PAnsiChar('Copy the selected file names(s) to the clipboard..'));
      cVerbAppendCopyFileFullPath: StrCopy(pszName, PAnsiChar('Append the selected filepath(s) to the clipboard..'));
      cVerbAppendCopyFileName: StrCopy(pszName, PAnsiChar('Append the selected file names(s) to the clipboard..'));
      else Result := E_INVALIDARG;
    end;
  end;
end;
 
type
  TContextMenuFactory = class(TComObjectFactory)
  public
    procedure UpdateRegistry(Register: Boolean); override;
  end;
 
procedure TContextMenuFactory.UpdateRegistry(Register: Boolean);
var ClassID: string;
begin
  if Register then
  begin
    inherited UpdateRegistry(Register);

    ClassID := GUIDToString(Class_ContextMenu);
    CreateRegKey('*\shellex', '', '');
    CreateRegKey('*\shellex\ContextMenuHandlers', '', '');
    CreateRegKey('*\shellex\ContextMenuHandlers\YouCustomNameYouWantForContext', '', ClassID);

    CreateRegKey('Directory\shellex', '', '');
    CreateRegKey('Directory\shellex\ContextMenuHandlers', '', '');
    CreateRegKey('Directory\shellex\ContextMenuHandlers\YouCustomNameYouWantForContext', '', ClassID);


  if (Win32Platform = VER_PLATFORM_WIN32_NT) then
    with TRegistry.Create do
      try
        RootKey := HKEY_LOCAL_MACHINE;
        OpenKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions', True);
        OpenKey('Approved', True);
        WriteString(ClassID, 'YouCustomNameYouWantForContext Context Menu Shell Extension');
      finally
        Free;
      end;
  end
  else
  begin
    DeleteRegKey('*\shellex\ContextMenuHandlers\YouCustomNameYouWantForContext');
    DeleteRegKey('Directory\shellex\ContextMenuHandlers\YouCustomNameYouWantForContext');
    inherited UpdateRegistry(Register);
  end;
end;
 
initialization
  TContextMenuFactory.Create(ComServer, TContextMenu, Class_ContextMenu,
    '', 'YouCustomNameYouWantForContext Context Menu Shell Extension', ciMultiInstance, tmApartment);
  gAllPaths:='';
end.
