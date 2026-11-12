program RALWebPagesExample;

{$APPTYPE CONSOLE}

{$I PascalRAL.inc}

uses
  System.Classes, System.SysUtils,

  // Choose here the engine of the server
  RALIndyServer,

  RALServer, RALRequest, RALResponse, RALTypes, RALConsts, RALParams, RALKeyValueStore,
  RALTemplate, RALViewModule, RALHtmx, RALWebModule, RALCSRF, RALUploadScan, RALClamAV;

type
  TApp = class
  private
    FWeb: TRALWebModule;
    FCSRF: TRALCSRFPlugin;
    function ItemsOf(ASession: TRALWebSession): TStringList;
    procedure Fill(ARequest: TRALRequest; AResponse: TRALResponse;
      AContext: TRALViewContext);
  public
    constructor Create(AWeb: TRALWebModule; ACSRF: TRALCSRFPlugin);
    // handlers of the views; they run on server threads
    procedure Index(Sender: TObject; ARequest: TRALRequest; AResponse: TRALResponse;
      AContext: TRALViewContext; var ARender: boolean);
    procedure Items(Sender: TObject; ARequest: TRALRequest; AResponse: TRALResponse;
      AContext: TRALViewContext; var ARender: boolean);
    procedure Login(Sender: TObject; ARequest: TRALRequest; AResponse: TRALResponse;
      AContext: TRALViewContext; var ARender: boolean);
    procedure Logout(Sender: TObject; ARequest: TRALRequest; AResponse: TRALResponse;
      AContext: TRALViewContext; var ARender: boolean);
    procedure Upload(Sender: TObject; ARequest: TRALRequest; AResponse: TRALResponse;
      AContext: TRALViewContext; var ARender: boolean);
  end;

const
  LAYOUT_HTML =
    '<!DOCTYPE html><html><head><meta charset="utf-8"><title>RAL web pages</title>' +
    '<script src="https://unpkg.com/htmx.org@2.0.4"></script></head>' +
    // every HTMX request carries the CSRF token in the header
    '<body hx-headers=''{"X-CSRF-Token":"{{csrf_token}}"}''>' +
    '{{$content}}{{/content}}</body></html>';

  LIST_HTML =
    '<ul id="list">{{#items}}<li>{{.}}</li>{{/items}}</ul>';

  INDEX_HTML =
    '<h1>RAL web pages</h1>' +
    '{{#logged}}<p>Hello, {{user}}!</p>' +
    '<form method="post" action="/logout">{{{csrf_field}}}<button>Logout</button></form>{{/logged}}' +
    '{{^logged}}<form method="post" action="/login">{{{csrf_field}}}' +
    '<input name="user" placeholder="your name"><button>Login</button></form>{{/logged}}' +
    '<h2>Todo list (kept in the session)</h2>' +
    '{{>list}}' +
    // the view answers only the fragment (the list) because the request is HTMX
    '<form hx-post="/items" hx-target="#list" hx-swap="outerHTML">' +
    '<input name="item" placeholder="new item"><button>Add</button></form>' +
    '<h2>Upload</h2>' +
    '<form method="post" action="/upload" enctype="multipart/form-data">{{{csrf_field}}}' +
    '<input type="file" name="file"><button>Send</button></form>' +
    '<p><small>Every upload goes through ClamAV (127.0.0.1:3310). With clamd running, a file ' +
    'with the EICAR test string is refused with 422; without clamd the upload is accepted ' +
    '(ScanFailAction = sfaAccept).</small></p>' +
    '{{#upload_msg}}<p>{{upload_msg}}</p>{{/upload_msg}}';

constructor TApp.Create(AWeb: TRALWebModule; ACSRF: TRALCSRFPlugin);
begin
  inherited Create;
  FWeb := AWeb;
  FCSRF := ACSRF;
end;

// the list is one session value: the items joined by line breaks
function TApp.ItemsOf(ASession: TRALWebSession): TStringList;
begin
  Result := TStringList.Create;
  Result.Text := string(ASession.Values['items']);
end;

procedure TApp.Fill(ARequest: TRALRequest; AResponse: TRALResponse;
  AContext: TRALViewContext);
var
  vSession: TRALWebSession;
  vUser: string;
begin
  vSession := FWeb.OpenSession(ARequest, AResponse);
  vUser := string(vSession.Values['user']);
  AContext.Add('user', StringRAL(vUser));
  AContext.AddBoolean('logged', vUser <> '');
  AContext.AddOwned('items', ItemsOf(vSession));
end;

procedure TApp.Index(Sender: TObject; ARequest: TRALRequest; AResponse: TRALResponse;
  AContext: TRALViewContext; var ARender: boolean);
begin
  Fill(ARequest, AResponse, AContext);
end;

procedure TApp.Items(Sender: TObject; ARequest: TRALRequest; AResponse: TRALResponse;
  AContext: TRALViewContext; var ARender: boolean);
var
  vSession: TRALWebSession;
  vList: TStringList;
  vParam: TRALParam;
  vText: string;
begin
  vSession := FWeb.OpenSession(ARequest, AResponse);
  vParam := ARequest.Params.Get['item'];
  if vParam <> nil then
  begin
    vText := Trim(StringReplace(StringReplace(string(vParam.AsString), #13, ' ', [rfReplaceAll]),
      #10, ' ', [rfReplaceAll]));
    if vText <> '' then
    begin
      vList := ItemsOf(vSession);
      try
        vList.Add(vText);
        vSession.Values['items'] := StringRAL(vList.Text);
      finally
        FreeAndNil(vList);
      end;
      TRALHtmx.TriggerEvent(AResponse, 'itemAdded');
    end;
  end;
  AContext.AddOwned('items', ItemsOf(vSession));
end;

procedure TApp.Login(Sender: TObject; ARequest: TRALRequest; AResponse: TRALResponse;
  AContext: TRALViewContext; var ARender: boolean);
var
  vSession: TRALWebSession;
  vParam: TRALParam;
begin
  // a new session id at the login, keeping what the session holds (session fixation)
  vSession := FWeb.RegenerateSession(ARequest, AResponse);
  vParam := ARequest.Params.Get['user'];
  if vParam <> nil then
    vSession.Values['user'] := StringRAL(Trim(string(vParam.AsString)));
  Fill(ARequest, AResponse, AContext);
end;

procedure TApp.Logout(Sender: TObject; ARequest: TRALRequest; AResponse: TRALResponse;
  AContext: TRALViewContext; var ARender: boolean);
begin
  FWeb.EndSession(ARequest, AResponse);
  AContext.Add('user', '');
  AContext.AddBoolean('logged', False);
  AContext.AddOwned('items', TStringList.Create);
end;

procedure TApp.Upload(Sender: TObject; ARequest: TRALRequest; AResponse: TRALResponse;
  AContext: TRALViewContext; var ARender: boolean);
var
  vInt: integer;
  vParam: TRALParam;
  vMsg: string;
begin
  // the scan plugin already ran: an infected file never gets here
  vMsg := 'no file received';
  for vInt := 0 to ARequest.Params.Count - 1 do
  begin
    vParam := ARequest.Params.Index[vInt];
    if (vParam.Kind = rpkBODY) and (vParam.FileName <> '') then
      vMsg := 'received ' + string(vParam.FileName) + ' (' +
        IntToStr(vParam.ContentSize) + ' bytes)';
  end;
  Fill(ARequest, AResponse, AContext);
  AContext.Add('upload_msg', StringRAL(vMsg));
end;

var
  FApp: TApp;
  FServer: TRALServer;
  FEngine: TRALMustacheEngine;
  FStore: TRALFileStore;
  FWeb: TRALWebModule;
  FViews: TRALViewModule;
  FCSRF: TRALCSRFPlugin;
  FScan: TRALUploadScanPlugin;
  FClam: TRALClamAVScanner;
begin
  FServer := TRALIndyServer.Create(nil);
  FEngine := TRALMustacheEngine.Create(nil);
  FStore := TRALFileStore.Create(nil);
  FWeb := TRALWebModule.Create(nil);
  FViews := TRALViewModule.Create(nil);
  FCSRF := TRALCSRFPlugin.Create(nil);
  FClam := TRALClamAVScanner.Create(nil);
  FScan := TRALUploadScanPlugin.Create(nil);
  FApp := TApp.Create(FWeb, FCSRF);
  try
    // templates added in code; with TemplateRoot they could be files
    FEngine.AddTemplate('layout', LAYOUT_HTML);
    FEngine.AddTemplate('list', LIST_HTML);
    FEngine.AddTemplate('index', INDEX_HTML);
    FEngine.Layout := 'layout';

    // sessions in a file store (several processes can share it).
    // To keep them in the browser instead, no state in the server:
    //   FWeb.SessionStorage := wssCookie;
    //   FWeb.SessionSecret := 'a long secret shared by every server';
    FStore.Folder := ExtractFilePath(ParamStr(0)) + 'sessions';
    ForceDirectories(FStore.Folder);
    FWeb.Server := FServer;
    FWeb.SessionStore := FStore;
    FWeb.SessionStorage := wssStore;

    // tokens bound to the session of the browser
    FCSRF.Server := FServer;
    FCSRF.WebModule := FWeb;

    // without clamd the scan fails and the upload is accepted
    FClam.Host := '127.0.0.1';
    FClam.Port := 3310;
    FScan.Server := FServer;
    FScan.Scanner := FClam;
    FScan.ScanFailAction := sfaAccept;

    FViews.Server := FServer;
    FViews.Engine := FEngine;
    FViews.CreateView('/', 'index', {$IFDEF FPC}@{$ENDIF}FApp.Index);
    FViews.CreateView('/items', 'list', {$IFDEF FPC}@{$ENDIF}FApp.Items).AllowedMethods := [amPOST];
    FViews.CreateView('/login', 'index', {$IFDEF FPC}@{$ENDIF}FApp.Login).AllowedMethods := [amPOST];
    FViews.CreateView('/logout', 'index', {$IFDEF FPC}@{$ENDIF}FApp.Logout).AllowedMethods := [amPOST];
    FViews.CreateView('/upload', 'index', {$IFDEF FPC}@{$ENDIF}FApp.Upload).AllowedMethods := [amPOST];

    FServer.Port := 8000;
    FServer.Start;
    WriteLn('RALServer running on Port ', FServer.Port, ', open http://localhost:8000/');
    WriteLn('Press ENTER to finish');
    ReadLn;
  finally
    FServer.Stop;
    FreeAndNil(FApp);
    FreeAndNil(FScan);
    FreeAndNil(FClam);
    FreeAndNil(FCSRF);
    FreeAndNil(FViews);
    FreeAndNil(FWeb);
    FreeAndNil(FStore);
    FreeAndNil(FEngine);
    FreeAndNil(FServer);
  end;
end.
