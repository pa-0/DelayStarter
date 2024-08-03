unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, WinInet, StdCtrls, ExtCtrls, ShellAPI, IniFiles, ComCtrls;

type
  TMain = class(TForm)
    Panel: TPanel;
    TextLbl: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    procedure ThreadTerminate(Sender: TObject);
    { Private declarations }
  public
    { Public declarations }
  end;

  TMyThread = class(TThread)
    private
      { Private declarations }
      procedure UpdateUI;
    protected
      procedure Execute; override;
  end;

var
  Main: TMain;
  MyThread: TMyThread;
  AppsList: TStringList;
  FirstRun: boolean;
  StartTime, LaunchTime: int64;

  IDS_WAITING_INTERNET_CONNECTION, IDS_REMAINING_TIME: string;

implementation

{$R *.dfm}

function HTTPGet(URL: string): string;
var
  hSession, hUrl: HINTERNET;
  Buffer: array [1..8192] of Byte;
  dwFlags, BufferLen: DWORD;
  StrStream: TStringStream;
begin
  Result:='';
  hSession:=InternetOpen('Mozilla/4.0 (MSIE 6.0; Windows NT 5.1)', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if Assigned(hSession) then begin

    if Copy(LowerCase(URL), 1, 8) = 'https://' then
      dwFlags:=INTERNET_FLAG_SECURE
    else
      dwFlags:=INTERNET_FLAG_RELOAD;

    hUrl:=InternetOpenUrl(hSession, PChar(URL), nil, 0, dwFlags, 0);
    if Assigned(hUrl) then begin
      StrStream:=TStringStream.Create('');
      try
        repeat
          FillChar(Buffer, SizeOf(Buffer), 0);
          BufferLen:=0;
          if InternetReadFile(hURL, @Buffer, SizeOf(Buffer), BufferLen) then
            StrStream.WriteBuffer(Buffer, BufferLen)
          else
            Break;
          Application.ProcessMessages;
        until BufferLen = 0;
        Result:=StrStream.DataString;
      except
        Result:='';
      end;
      StrStream.Free;

      InternetCloseHandle(hUrl);
    end;

    InternetCloseHandle(hSession);
  end;
end;

procedure TMain.ThreadTerminate(Sender: TObject);
begin
  //MyThread.Free; // блокирует закрывание
  MyThread:=nil;
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

function GetLocaleInformation(Flag: integer): string;
var
  pcLCA: array [0..20] of Char;
begin
  if GetLocaleInfo(LOCALE_SYSTEM_DEFAULT, Flag, pcLCA, 19) <= 0 then
    pcLCA[0]:=#0;
  Result:=pcLCA;
end;

procedure TMain.FormCreate(Sender: TObject);
var
  Ini: TIniFile;
begin
  StartTime:=GetTickCount;

  Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Setup.ini');
  FirstRun:=Ini.ReadBool('Main', 'FirstRun', False);
  LaunchTime:=Ini.ReadInteger('Main', 'LaunchTime', 0) * 1000;
  Ini.Free;

  AppsList:=TStringList.Create;
  if FileExists(ExtractFilePath(ParamStr(0)) + 'Apps.txt') then
    AppsList.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'Apps.txt');
  MyThread:=TMyThread.Create(False);
  MyThread.Priority:=tpNormal;
  MyThread.OnTerminate:=ThreadTerminate;

  Application.Title:=Caption;
  if GetLocaleInformation(LOCALE_SENGLANGUAGE) <> 'Russian' then begin
    IDS_WAITING_INTERNET_CONNECTION:='Waiting for internet connection...';
    IDS_REMAINING_TIME:='Remaining time: ';
  end else begin
    IDS_WAITING_INTERNET_CONNECTION:='Ждём подключения интернет-соединения...';
    IDS_REMAINING_TIME:='Осталось времени: ';
  end;
  TextLbl.Caption:=IDS_WAITING_INTERNET_CONNECTION + #13#10 + IDS_REMAINING_TIME + '0:00';
end;

procedure TMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  AppsList.Free;
  if Assigned(MyThread) then
  begin
    MyThread.Terminate;
    MyThread.WaitFor;
    MyThread.Free;
    MyThread:=nil;
  end;
end;

function MsToMinSec(Ms: int64): string;
var
  Minutes, Seconds: Integer;
begin
  Seconds:=Ms div 1000;
  Minutes:=Seconds div 60;
  Seconds:=Seconds mod 60;
  Result:=Format('%d:%2.2d', [Minutes, Seconds]);
end;

procedure TMyThread.UpdateUI;
var
  RemainingTime: int64;
begin
  RemainingTime:=LaunchTime - (GetTickCount - StartTime);
  if RemainingTime < 0 then RemainingTime:=0;

  Main.TextLbl.Caption:=IDS_WAITING_INTERNET_CONNECTION + #13#10 + IDS_REMAINING_TIME + MsToMinSec(RemainingTime);
end;

procedure TMyThread.Execute;
var
  Ini: TIniFile;
  AppPath, AppParams: string;
  i, DelimPos: integer;
begin
  while not Terminated do begin
    Synchronize(UpdateUI);

    if HTTPGet('http://www.msftconnecttest.com/connecttest.txt') = 'Microsoft Connect Test' then begin

      if FirstRun then begin
        Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Setup.ini');
        Ini.WriteBool('Main', 'FirstRun', False);
        Ini.WriteInteger('Main', 'LaunchTime', (GetTickCount - StartTime) div 1000);
        Ini.Free;
      end;

      for i:=0 to AppsList.Count - 1 do begin

        if Trim(AppsList.Strings[i]) = '' then Continue;
        if Trim(AppsList.Strings[i])[1] = '#' then Continue;

        DelimPos:=Pos('|', AppsList.Strings[i]);

        if DelimPos > 0 then begin
          AppPath:=Copy(AppsList.Strings[i], 1, DelimPos - 1);
          AppParams:=Copy(AppsList.Strings[i], DelimPos + 1, Length(AppsList.Strings[i]) - DelimPos);
        end else begin
          AppPath:=AppsList.Strings[i];
          AppParams:='';
        end;

        if not FileExists(AppsList.Strings[i]) then Continue;

        ShellExecute(0, 'open', PChar(AppPath), PChar(AppParams), nil, SW_SHOWNORMAL);

      end;

      Terminate;
    end;

    Sleep(1000);
  end;
end;

end.
