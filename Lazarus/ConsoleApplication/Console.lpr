program Console;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, CustApp, RALfpHTTPServer, RALRequest, RALResponse;

type

  { TRALApplication }

  TRALApplication = class(TCustomApplication)
  private
    FServer : TRALfpHttpServer;
  protected
    procedure DoRun; override;
    procedure teste(Sender: TObject; ARequest: TRALRequest; AResponse: TRALResponse);
  public
    constructor Create(TheOwner : TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
  end;

{ TRALApplication }

procedure TRALApplication.DoRun;
var
  ErrorMsg : String;
begin
  WriteHelp;
  // quick check parameters
  ErrorMsg :=CheckOptions('h', 'help');
  if ErrorMsg <>'' then begin
    ShowException(Exception.Create(ErrorMsg));
    Terminate;
    Exit;
  end;

  // parse parameters
  if HasOption('h', 'help') then begin
    WriteHelp;
    Terminate;
    Exit;
  end;

  FServer.CreateRoute('teste',@teste);
  FServer.Active := True;

  ReadLn;

  { add your program here }

  // stop program loop
  Terminate;
end;

procedure TRALApplication.teste(Sender : TObject; ARequest : TRALRequest; AResponse : TRALResponse);
begin
  AResponse.ResponseText := 'RALTeste';
end;

constructor TRALApplication.Create(TheOwner : TComponent);
begin
  inherited Create(TheOwner);
  StopOnException :=True;
  FServer := TRALfpHttpServer.Create(nil);
end;

destructor TRALApplication.Destroy;
begin
  FServer.Free;
  inherited Destroy;
end;

procedure TRALApplication.WriteHelp;
begin
  { add your help code here }
  writeln('Usage: ', ExeName, ' -h');
end;

var
  Application : TRALApplication;
begin
  Application := TRALApplication.Create(nil);
  Application.Title :='RAL Application';
  Application.Run;
  Application.Free;
end.

