program RALStatefulExample;

{$APPTYPE CONSOLE}
{$IFDEF FPC}
  {$MODE DELPHI}{$H+}
{$ENDIF}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils,
  RALTypes, RALMIMETypes, RALParams, RALRequest, RALResponse, RALClient, RALInProc,
  RALStatefulModule;

// Resources with state with PascalRAL (package RALModuleStatefulPackage), on the
// InProc engine (no port opened): the routes of TCart are methods, its item list is
// a plain field, and TRALStatefulModule gives each user session its own TCart. Two
// users (ana and bia) fill their carts; each sees only its own.

type
  TCart = class(TRALStatefulResource)
  private
    FItems: TStringList;
    procedure Add(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure Show(ARequest: TRALRequest; AResponse: TRALResponse);
  protected
    procedure DefineRoutes; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

constructor TCart.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FItems := TStringList.Create;
end;

destructor TCart.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

procedure TCart.DefineRoutes;
begin
  Route('cart/add', Add, 'adds ?item= to the cart of the session');
  Route('cart', Show, 'the cart of the session');
end;

procedure TCart.Add(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  // a plain field: the calls of one session never run at the same time
  FItems.Add(string(ARequest.ParamByName('item').AsString));
  AResponse.Answer(200, StringRAL(IntToStr(FItems.Count) + ' item(s)'), rctTEXTPLAIN);
end;

procedure TCart.Show(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(200, StringRAL(FItems.CommaText), rctTEXTPLAIN);
end;

{ One user of the demo: keeps the session cookie the server gave it. }
type
  TUser = class
  public
    Name, Cookie: string;
    Client: TRALClient;
    constructor Create(const AName: string);
    destructor Destroy; override;
    function Get(const APath: string): string;
  end;

constructor TUser.Create(const AName: string);
begin
  Name := AName;
  Client := TRALClient.Create(nil);
  Client.EngineType := 'InProc';
  Client.BaseURL.Text := 'inproc://shop';
end;

destructor TUser.Destroy;
begin
  Client.Free;
  inherited Destroy;
end;

function TUser.Get(const APath: string): string;
var
  vResp: TRALResponse;
  vCookie: TRALCookie;
begin
  Client.Request.Clear;
  if Cookie <> '' then
    Client.Request.AddCookie('ralres', StringRAL(Cookie));
  Client.Get(StringRAL(APath), vResp);
  try
    Result := string(vResp.ResponseText);
    vCookie := GetRALCookieFromParam('ralres', vResp.Params);
    if vCookie.Value <> '' then
      Cookie := string(vCookie.Value);
  finally
    vResp.Free;
  end;
  WriteLn(Name, ' GET /', APath, ' -> ', Result);
end;

var
  FServer: TRALInProcServer;
  FCarts: TRALStatefulModule;
  FAna, FBia: TUser;
begin
  RALRegisterResource(TCart);
  FServer := TRALInProcServer.Create(nil);
  FCarts := TRALStatefulModule.Create(nil);
  FAna := TUser.Create('ana');
  FBia := TUser.Create('bia');
  try
    FServer.ServerName := 'shop';
    FCarts.ResourceClass := 'TCart';
    FCarts.Lifetime := mlPerSession;
    FCarts.Server := FServer;
    FServer.Active := True;

    FAna.Get('cart/add?item=pizza');
    FBia.Get('cart/add?item=salad');
    FAna.Get('cart/add?item=soda');
    FAna.Get('cart');
    FBia.Get('cart');
    WriteLn('sessions alive: ', FCarts.SessionCount);
    FServer.Active := False;
  finally
    FBia.Free;
    FAna.Free;
    FCarts.Free;
    FServer.Free;
  end;
end.
