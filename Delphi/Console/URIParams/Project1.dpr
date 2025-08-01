// by PascalRAL - Console App: 20/06/2025 11:09:03
program Project1;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  SysUtils, Classes,
  RALServer, RALRequest, RALResponse, RALRoutes, RALTypes, RALConsts,
//  RALIndyServer,
  RALSynopseServer,
//  RALSaguiServer,
  RALMimeTypes, RALJson;

type
  { TRALApplication }

  TRALApplication = class(TComponent)
  private
    FServer: TRALServer;
  protected
    procedure UriReply(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure AnyUriReply(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure Run;
  public
    constructor Create(Owner: TComponent); override;
    destructor Destroy; override;
  end;

{ TRALApplication }

procedure TRALApplication.AnyUriReply(ARequest: TRALRequest;
  AResponse: TRALResponse);
begin
  AResponse.Answer(HTTP_OK, ARequest.Params.AsString, rctTEXTPLAIN);
end;

constructor TRALApplication.Create(Owner: TComponent);
begin
  inherited;
//  FServer := TRALIndyServer.Create(nil);
  FServer := TRALSynopseServer.Create(nil);
//  FServer := TRALSaguiServer.Create(nil);
end;

destructor TRALApplication.Destroy;
begin
  FreeAndNil(FServer);
  inherited;
end;

procedure TRALApplication.Run;
begin
  inherited;
  // this will allow any URI ammount in the route
  FServer.CreateRoute('/uri', AnyUriReply).AllowURIParams := true;

  // The above one line statement is the same as the commented code below:
  {
   var
     Route: TRALRoute;

   Route := FServer.CreateRoute('/uri', AnyUriReply);
   Route.AllowURIParams := true;
  }

  // this will allow only pre-determined URI params in the route
  FServer.CreateRoute('/uri/:id1/:id2/:id3', UriReply);

  FServer.Start;
  Writeln('server running on port: ', FServer.Port);
  writeln('press any key to end application...');
  Readln;
end;

procedure TRALApplication.UriReply(ARequest: TRALRequest;
  AResponse: TRALResponse);
begin
  AResponse.Answer(HTTP_OK, ARequest.Params.AsString, rctTEXTPLAIN);
end;

var
  Application: TRALApplication;

begin
  ReportMemoryLeaksOnShutdown := true;
  Application := TRALApplication.Create(nil);
  Application.Run;
  Application.Free;
end.
