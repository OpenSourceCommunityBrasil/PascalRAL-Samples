program Console;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils, System.JSON,
  Classes,
  RALServer, RALSynopseServer, RALRequest, RALResponse, RALConsts, RALMIMETypes;

type
  { TRALApplication }

  TRALApplication = class(TComponent)
  private
    FServer: TRALServer;
  protected
    procedure teste(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure ping(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure Run;
  public
    constructor Create(Owner: TComponent); override;
    destructor Destroy; override;
  end;

  { TRALApplication }

constructor TRALApplication.Create(Owner: TComponent);
begin
  inherited;
  FServer := TRALSynopseServer.Create(nil);
end;

destructor TRALApplication.Destroy;
begin
  FServer.Free;
  inherited;
end;

procedure TRALApplication.ping(ARequest: TRALRequest; AResponse: TRALResponse);
var
  Json: TJSONObject;
begin
  JSON := TJSONObject.Create;
  try
    JSON.AddPair('HeaderParams', ARequest.Params.AsString);
    JSON.AddPair('RequestBody', ARequest.Body.AsString);
    JSON.AddPair('ParamsAsJSON', ARequest.Params.AsJSON);
    AResponse.Answer(HTTP_OK, JSON.ToJSON, rctAPPLICATIONJSON);
  finally
    JSON.Free;
  end;
end;

procedure TRALApplication.Run;
begin
  inherited;
  FServer.CreateRoute('teste', teste);
  FServer.CreateRoute('ping', ping);
  FServer.Start;
  Writeln('server running on port', fserver.Port);
  writeln('press any key to end application...');
  Readln;
end;

procedure TRALApplication.teste(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(200, 'RALTeste');
end;

var
  Application: TRALApplication;

begin
  Application := TRALApplication.Create(nil);
  Application.Run;
  Application.Free;
end.
