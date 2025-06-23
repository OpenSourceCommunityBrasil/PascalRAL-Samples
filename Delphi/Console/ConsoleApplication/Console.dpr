program Console;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  Classes,
  RALIndyServer,
  RALRequest,
  RALResponse;

type
  { TRALApplication }

  TRALApplication = class(TComponent)
  private
    FServer: TRALIndyServer;
  protected
    procedure teste(ARequest: TRALRequest; AResponse: TRALResponse);
    procedure Run;
  public
    constructor Create(Owner: TComponent); override;
    destructor Destroy; override;
  end;

  { TRALApplication }

constructor TRALApplication.Create(Owner: TComponent);
begin
  inherited;
  FServer := TRALIndyServer.Create(nil);
end;

destructor TRALApplication.Destroy;
begin
  FServer.Free;
  inherited;
end;

procedure TRALApplication.Run;
begin
  inherited;
  FServer.CreateRoute('teste', teste);
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
