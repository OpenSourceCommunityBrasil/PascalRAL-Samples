program Console;

{$mode objfpc}{$H+}

uses
 {$IFDEF UNIX}
  cthreads,
    {$ENDIF}
  Classes,
  SysUtils,
  CustApp,
  RALfpHTTPServer,
  RALRequest,
  RALResponse;

type

  { TRALApplication }

  TRALApplication = class(TCustomApplication)
  private
    FServer: TRALfpHttpServer;
  protected
    procedure Run;
    procedure teste(ARequest: TRALRequest; AResponse: TRALResponse);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  { TRALApplication }

  procedure TRALApplication.Run;
  var
    ErrorMsg: string;
  begin
    FServer.CreateRoute('teste', @teste);
    FServer.Active := True;
    writeln('server active on port', FServer.Port);
    writeln('press any key to terminate app...');
    ReadLn;
    Terminate;
  end;

  procedure TRALApplication.teste(ARequest: TRALRequest; AResponse: TRALResponse);
  begin
    AResponse.ResponseText := 'RALTeste';
  end;

  constructor TRALApplication.Create(AOwner: TComponent);
  begin
    inherited Create(AOwner);
    StopOnException := True;
    FServer := TRALfpHttpServer.Create(nil);
  end;

  destructor TRALApplication.Destroy;
  begin
    FServer.Free;
    inherited Destroy;
  end;

var
  Application: TRALApplication;
begin
  Application := TRALApplication.Create(nil);
  Application.Title := 'RAL Application';
  Application.Run;
  Application.Free;
end.
