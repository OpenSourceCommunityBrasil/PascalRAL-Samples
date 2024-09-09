program cgi_ral;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  RALCGIServer,
  RALRequest,
  RALResponse;

type

  { TMyApp }

  TMyApp = class(TObject)
  public
    FMyCGI : TRALCGIServer;
  public
    constructor Create;
    destructor Destroy; override;

    procedure teste(ARequest: TRALRequest; AResponse: TRALResponse);
  end;

{ TMyApp }

constructor TMyApp.Create;
begin
  FMyCGI := TRALCGIServer.Create(nil);
  FMyCGI.CreateRoute('/teste', teste);
  FMyCGI.Start;
end;

destructor TMyApp.Destroy;
begin
  FMyCGI.Free;
  inherited Destroy;
end;

procedure TMyApp.teste(ARequest: TRALRequest; AResponse: TRALResponse);
begin
  AResponse.Answer(200, 'teste');
end;

var
  vApp : TMyApp;

begin
  vApp := TMyApp.Create;
  vApp.Free;
end.
